require 'zip'
require 'seven_zip_ruby'
require 'filemagic'
require 'mime/types'
require 'minitar'
require 'zlib'
require 'rest-client'


class Datafile < ActiveRecord::Base
  include ActiveModel::Serialization
  include Viewable
  belongs_to :dataset
  has_many :nested_items, dependent: :destroy
  audited associated_with: :dataset

  WEB_ID_LENGTH = 5

  ALLOWED_CHAR_NUM = 1024 * 8
  ALLOWED_DISPLAY_BYTES = ALLOWED_CHAR_NUM * 8

  before_create { self.web_id ||= generate_web_id }

  before_destroy :destroy_job
  before_destroy :remove_binary

  def to_param
    self.web_id
  end

  def as_json(options={})
    super(:only => [:web_id, :binary_name, :binary_size, :medusa_id, :storage_root, :storage_key, :created_at, :updated_at])
  end

  def file_download_tallies
    FileDownloadTally.where(file_web_id: self.web_id)
  end

  def total_downloads
    FileDownloadTally.where(file_web_id: self.web_id).sum :tally
  end

  def bytestream_name
    self.binary_name
  end

  def bytestream_size

    if binary_size
      binary_size
    elsif self.current_root && current_root.exist?(self.storage_key)
      self.binary_size = self.current_root.size(self.storage_key)
      self.save
      binary_size
    else
      Rails.logger.warn("binary not found for datafile: #{self.web_id} root: #{self.storage_root}, key: #{self.storage_key}")
      0
    end
  end

  def current_root
    Application.storage_manager.root_set.at(self.storage_root)
  end

  def storage_root_bucket
    if IDB_CONFIG[:aws][:s3_mode]
      self.current_root.bucket
    else
      nil
    end
  end

  def storage_key_with_prefix
    if IDB_CONFIG[:aws][:s3_mode]
      "#{self.current_root.prefix}#{self.storage_key}"
    else
      self.storage_key
    end
  end

  def storage_root_path
    if IDB_CONFIG[:aws][:s3_mode]
      nil
    else
      if current_root
        current_root.real_path
      else
        nil
      end
    end
  end

  # within the context of the databank server mounts
  def filepath
    base = self.storage_root_path
    if base
      File.join(base, self.storage_key)
    else
      raise("no filesystem path found for datafile: #{self.web_id}")
    end
  end

  #Set this up so that we use local storage for small files, for some definition of small
  # might want to extract this elsewhere so that is generally available and easy to make
  # robust for whatever application.
  def tmpdir_for_with_input_file
    expected_size = self.binary_size || current_root.size(self.storage_key)
    if expected_size > 500.megabytes
      Application.storage_manager.tmpdir
    else
      Dir.tmpdir
    end
  end

  #wrap the storage root's ability to yield an io on the content
  def with_input_io
    current_root.with_input_io(self.storage_key) do |io|
      yield io
    end
  end

  #wrap the storage root's ability to yield a file path having the appropriate content in it
  def with_input_file
    current_root.with_input_file(self.storage_key, tmp_dir: tmpdir_for_with_input_file) do |file|
      yield file
    end
  end

  def exists_on_storage?
    current_root.exist?(self.key)
  end

  def remove_from_storage
    current_root.delete_content(self.key)
  end

  def name
    binary_name
  end

  # medusa mounts are different on iiif server
  def iiif_bytestream_path

    if storage_root == 'draft'
      File.join(IDB_CONFIG[:iiif][:draft_base], storage_key )
    elsif storage_root == 'medusa'
      File.join(IDB_CONFIG[:iiif][:medusa_base], storage_key )
    else
      raise("invalid storage_root found for datafile: #{self.web_id}")
    end

  end

  def file_extension
    filename_split = self.bytestream_name.split(".")
    if filename_split.count > 1 # otherwise cannot determine extension
      return filename_split.last
    else
      return ""
    end
  end

  def ip_downloaded_file_today(request_ip)
    DayFileDownload.where(["ip_address = ? and file_web_id = ? and download_date = ?",
                           request_ip,
                           self.web_id,
                           Date.current]).count > 0
  end

  def dataset_key
    dataset = Dataset.where(id: self.dataset_id).first
    if dataset
      return dataset.key
    else
      return nil
    end
  end

  # has side-effect of updating record if the bytestream is in medusa, but the record did not indicate
  # if bytestream is found the same in draft and medusa roots, the draft bytestream is deleted
  def in_medusa

    dataset = Dataset.find(self.dataset_id)

    return false unless dataset
    return false unless (dataset.identifier && dataset.identifier != '')

    in_medusa = false # start out with the assumption that it is not in medusa, then check and handle

    datafile_target_key = "#{dataset.dirname}/dataset_files/#{self.binary_name}"

    if Application.storage_manager.medusa_root.exist?(datafile_target_key)
      in_medusa = true

      if storage_root && storage_key && storage_root == 'draft' && storage_key != ''

        # If the binary object also exists in draft system, delete duplicate.
        #  Can't do full equivalence check (S3 etag is not always MD5), so check sizes.
        if Application.storage_manager.draft_root.exist?(self.storage_key)
          draft_size = Application.storage_manager.draft_root.size(self.storage_key)
          medusa_size = Application.storage_manager.medusa_root.size(datafile_target_key)

          if draft_size == medusa_size
            # If the ingest into Medusa was successful,
            # delete redundant binary object
            # and update Illinois Data Bank datafile record
            Application.storage_manager.draft_root.delete_content(self.storage_key)
            in_medusa = true
          else
            in_medusa = false
            exception_string("Datafile exists in both draft and medusa storage systems, but the sizes are different. Dataset: #{dataset.key}, Datafile: #{datafile.web_id}")
            notification = DatabankMailer.error(exception_string)
            notification.deliver_now
          end
        else
          in_medusa = true
        end
      else
        in_medusa = true
      end

      if in_medusa
        self.storage_root = 'medusa'
        self.storage_key = datafile_target_key
        self.save
      end
    else
      #Rails.logger.warn("Did not find in medusa")
    end
      in_medusa
  end

  def has_bytestream
    self.storage_root &&
        self.storage_root != "" &&
        self.storage_key &&
        self.storage_key != "" &&
        current_root.exist?(self.storage_key)
  end

  def record_download(request_ip)

    if Robot.exists?(address: request_ip)
      return nil
    end

    dataset = Dataset.find(self.dataset_id)

    if dataset.publication_state != Databank::PublicationState::DRAFT # ignore draft datasets

      unless dataset.ip_downloaded_dataset_today(request_ip)

        day_ds_download_set = DatasetDownloadTally.where(["dataset_key= ? and download_date = ?",
                                                          dataset.key,
                                                          Date.current])

        if day_ds_download_set.count == 1

          today_dataset_download = day_ds_download_set.first
          today_dataset_download.tally = today_dataset_download.tally + 1
          today_dataset_download.save
        elsif day_ds_download_set.count == 0
          DatasetDownloadTally.create(tally: 1,
                                      download_date: Date.current,
                                      dataset_key: dataset.key,
                                      doi: dataset.identifier)
        else
          Rails.logger.warn "unexpected number of dataset tally records for download of #{self.web_id} on #{Date.current} from #{request_ip}"
        end

      end

      unless ip_downloaded_file_today(request_ip)


        DayFileDownload.create(ip_address: request_ip,
                               download_date: Date.current,
                               file_web_id: self.web_id,
                               filename: self.bytestream_name,
                               dataset_key: dataset.key,
                               doi: dataset.identifier)

        day_df_download_set = FileDownloadTally.where(["file_web_id = ? and download_date = ?",
                                                       self.web_id,
                                                       Date.current])

        if day_df_download_set.count == 1
          today_file_download = day_df_download_set.first
          today_file_download.tally = today_file_download.tally + 1
          today_file_download.save
        elsif day_df_download_set.count == 0
          FileDownloadTally.create(tally: 1, download_date: Date.current, dataset_key: dataset.key, doi: dataset.identifier, file_web_id: self.web_id, filename: self.bytestream_name)
        else
          Rails.logger.warn "unexpected number of file tally records for download of #{self.web_id} on #{Date.current} from #{request_ip}"
        end

      end

    end

  end

  def remove_binary
    if storage_key
      if Application.storage_manager.draft_root.exist?(storage_key)
        Application.storage_manager.draft_root.delete_content(storage_key)
      end
      if Application.storage_manager.draft_root.exist?("#{storage_key}.info")
        Application.storage_manager.draft_root.delete_content("#{storage_key}.info")
      end
    end
  end

  def initiate_processing_task

    databank_task = DatabankTask.create_remote(self.web_id)

    if databank_task
      self.task_id = databank_task
      if self.task_id
        self.save
      else
        raise("error attempting to create remote task: #{self.web_id}")
      end
    else
      raise("error attempting to send datafile for processing: #{self.web_id}")
    end

  end

  def job
    if self.job_id
      Delayed::Job.where(id: self.job_id).first
    end
  end

  def job_status
    if self.job
      if job.locked_by
        return :processing
      else
        return :pending
      end
    else
      return :complete
    end
  end

  def destroy_job
    if self.job
      self.job.destroy
    end
  end

  def download_link
    case cfs_file.storage_root.root_type
    when :filesystem
      download_cfs_file_path(cfs_file)
    when :s3
      cfs_file.storage_root.presigned_get_url(cfs_file.key, response_content_disposition: disposition('attachment', cfs_file),
                                              response_content_type: safe_content_type(cfs_file))
    else
      raise "Unrecognized storage root type #{cfs_file.storage_root.type}"
    end
  end

  def self.peek_type_from_mime(mime_type, num_bytes)

    return Databank::PeekType::NONE unless num_bytes && mime_type && mime_type.length > 0

    mime_parts = mime_type.split("/")

    return Databank::PeekType::NONE unless mime_parts.length == 2

    text_subtypes = ['csv', 'xml', 'x-sh', 'x-javascript', 'json', 'r', 'rb']

    supported_image_subtypes = ['jp2', 'jpeg', 'dicom', 'gif', 'png', 'bmp']

    nonzip_archive_subtypes = ['x-7z-compressed', 'x-tar']

    pdf_subtypes = ['pdf', 'x-pdf']

    microsoft_subtypes = ['msword',
                          'vnd.openxmlformats-officedocument.wordprocessingml.document',
                          'vnd.openxmlformats-officedocument.wordprocessingml.template',
                          'vnd.ms-word.document.macroEnabled.12',
                          'vnd.ms-word.template.macroEnabled.12',
                          'vnd.ms-excel',
                          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                          'vnd.openxmlformats-officedocument.spreadsheetml.template',
                          'vnd.ms-excel.sheet.macroEnabled.12',
                          'vnd.ms-excel.template.macroEnabled.12',
                          'vnd.ms-excel.addin.macroEnabled.12',
                          'vnd.ms-excel.sheet.binary.macroEnabled.12',
                          'vnd.ms-powerpoint',
                          'vnd.openxmlformats-officedocument.presentationml.presentation',
                          'vnd.openxmlformats-officedocument.presentationml.template',
                          'vnd.openxmlformats-officedocument.presentationml.slideshow',
                          'vnd.ms-powerpoint.addin.macroEnabled.12',
                          'vnd.ms-powerpoint.presentation.macroEnabled.12',
                          'vnd.ms-powerpoint.template.macroEnabled.12',
                          'vnd.ms-powerpoint.slideshow.macroEnabled.12']

    subtype = mime_parts[1].downcase

    if mime_parts[0] == 'text' || text_subtypes.include?(subtype)
      if num_bytes > ALLOWED_DISPLAY_BYTES
        return Databank::PeekType::PART_TEXT
      else
        return Databank::PeekType::ALL_TEXT
      end
    elsif mime_parts[0] == 'image'
      if supported_image_subtypes.include?(subtype)
        return Databank::PeekType::IMAGE
      else
        return Databank::PeekType::NONE
      end
    elsif microsoft_subtypes.include?(subtype)
      return Databank::PeekType::MICROSOFT
    elsif pdf_subtypes.include?(subtype)
      return Databank::PeekType::PDF
    elsif subtype == 'zip'
      return Databank::PeekType::LISTING
    elsif nonzip_archive_subtypes.include?(subtype)
      return Databank::PeekType::LISTING
    else
      return Databank::PeekType::NONE
    end

  end

  def get_part_text_peek

    return nil unless self.current_root.exist?(self.storage_key)

    begin

      part_text_string = nil

      if IDB_CONFIG[:aws][:s3_mode]
        first_bytes = self.current_root.get_bytes(self.storage_key, 0, ALLOWED_DISPLAY_BYTES)

        part_text_string = first_bytes.string

      else
        File.open(self.filepath) do |file|
          part_text_string = file.read(ALLOWED_DISPLAY_BYTES)
        end
      end

      if part_text_string.encoding == Encoding::ASCII_8BIT
        part_text_string.force_encoding(Encoding::UTF_8)
      end

      if part_text_string.encoding == Encoding::UTF_8
        return part_text_string
      else
        part_text_string = part_text_string.encode("UTF-8",{invalid: :replace, undef: :replace})
        return part_text_string
      end
    rescue Aws::S3::Errors::NotFound
      return nil
    end
  end

  def get_all_text_peek

    return nil unless self.current_root.exist?(self.storage_key)

    begin
      all_text_string = current_root.as_string(self.storage_key)

      if all_text_string.encoding == Encoding::ASCII_8BIT
        all_text_string.force_encoding(Encoding::UTF_8)
      end

      if all_text_string.encoding == Encoding::UTF_8
        return all_text_string
      else
        all_text_string = all_text_string.encode("UTF-8",{invalid: :replace, undef: :replace})
        return all_text_string
      end
    rescue Aws::S3::Errors::NotFound
      return nil
    end
  end

  ##
  # Generates a guaranteed-unique web ID, of which there are
  # 36^WEB_ID_LENGTH available.
  #
  def generate_web_id
    proposed_id = nil
    while true
      proposed_id = (36 ** (WEB_ID_LENGTH - 1) +
          rand(36 ** WEB_ID_LENGTH - 36 ** (WEB_ID_LENGTH - 1))).to_s(36)
      break unless Datafile.find_by_web_id(proposed_id)
    end
    proposed_id
  end

end
