require 'zip'
require 'seven_zip_ruby'
require 'filemagic'
require 'mime/types'
require 'minitar'
require 'zlib'


class Datafile < ActiveRecord::Base
  include ActiveModel::Serialization
  include Viewable
  mount_uploader :binary, BinaryUploader
  belongs_to :dataset
  has_many :nested_items, dependent: :destroy
  audited associated_with: :dataset

  WEB_ID_LENGTH = 5

  before_create { self.web_id ||= generate_web_id }

  before_destroy 'destroy_job'
  before_destroy 'remove_directory'

  # after_save 'chmod_binary_for_medusa'

  def to_param
    self.web_id
  end

  def as_json(options={})
    super(:only => [:web_id, :binary_name, :binary_size, :medusa_id, :created_at, :updated_at])
  end

  def file_download_tallies
    FileDownloadTally.where(file_web_id: self.web_id)
  end

  def total_downloads
    FileDownloadTally.where(file_web_id: self.web_id).sum :tally
  end

  def bytestream_name
    return_name = ""
    if self.binary_name && self.binary_name != ""
      return_name = self.binary_name
    elsif self.binary && self.binary.file
      return_name = self.binary.file.filename
    else
      return "error: filename not found"
    end
    return_name
  end

  def bytestream_size

    if self.binary_size
      self.binary_size
    elsif self.binary
      self.binary.size
    else
      0
    end

  end

  def storage_root_bucket
    if IDB_CONFIG[:aws][:s3_mode] == true

      return self.root_set.at(self.storage_root)[:bucket]

    else
      return nil
    end
  end

  def storage_root_path
    if IDB_CONFIG[:aws][:s3_mode] == false

      return self.root_set.at(self.storage_root)[:real_path]

    else
      return nil
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

  def bytestream_path
    if (self.medusa_path.nil? || self.medusa_path.empty?) && self.binary && self.binary.path
      return self.binary.path

    elsif !self.medusa_path.nil? && !self.medusa_path.empty?
      return "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{self.medusa_path}"

    elsif self.storage_root && self.storage_root !=''

      if self.storage_prefix && self.storage_prefix != ''
        return join(self.storage_root, self.storage_prefix, self.storage_key)
      else
        return join(self.storage_root, self.storage_key)
      end

    end
  end

  def iiif_bytestream_path
    if self.medusa_path.nil? || self.medusa_path.empty?
      self.binary.path
    else
      "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{IDB_CONFIG[:iiif_medusa_group]}/#{self.medusa_path}"
    end
  end

  def ip_downloaded_file_today(request_ip)
    DayFileDownload.where(["ip_address = ? and file_web_id = ? and download_date = ?", request_ip, self.web_id, Date.current]).count > 0
  end

  def dataset_key
    dataset = Dataset.where(id: self.dataset_id).first
    if dataset
      return dataset.key
    else
      return nil
    end
  end


  def content_files

    content_files_array = Array.new
    entries = self.nested_items
      for entry in entries
        if !entry.is_directory? && entry.item_name.strip() != '.DS_Store'
          content_file_hash = {}
          content_file_hash['content_filepath'] = entry.item_path
          content_file_hash['content_filename'] = entry.item_name
          content_file_hash['file_format'] = entry.media_type
          content_files_array.push(content_file_hash)
        end
      end
    content_files_array

  end

  def has_bytestream
    (self.binary && self.binary.file  && self.binary.size > 0 ) ||
        (self.medusa_path && self.medusa_path != "") ||
        (self.storage_root && self.storage_root != "")
  end

  def tar_contents()

    entry_list_text = `tar -tf "#{self.bytestream_path}"`

    entry_list = entry_list_text.split("\n")

    content_list = []

    entry_list.each do |entry|

      if entry[-1] != "/" # means directory

        content_path_array = entry.split("/")

        if content_path_array[-1] && (content_path_array[-1]).exclude?('.DS_Store') && (content_path_array[-1]).exclude?('__MACOSX')

          content_file_hash = {}
          content_file_hash['content_filename']=content_path_array[-1]

          type_search_result = MIME::Types.type_for(content_file_hash['content_filename'])

          if type_search_result.length > 0

            content_file_hash['file_format'] = type_search_result.first.content_type

          else
            content_file_hash['file_format'] = 'application/unknown'

          end

          content_file_hash['determination'] = 'lookup'
          content_list.push(content_file_hash)
        end
      end

    end

    content_list

  end

  def record_download(request_ip)

    if Robot.exists?(address: request_ip)
      return nil
    end

    dataset = Dataset.find(self.dataset_id)

    if dataset && dataset.identifier && dataset.identifier != "" # ignore draft datasets

      unless dataset.ip_downloaded_dataset_today(request_ip)

        today_dataset_download_relation = DatasetDownloadTally.where(["dataset_key= ? and download_date = ?", dataset.key, Date.current])

        if today_dataset_download_relation.count == 1

          today_dataset_download = today_dataset_download_relation.first
          today_dataset_download.tally = today_dataset_download.tally + 1
          today_dataset_download.save
        elsif today_dataset_download_relation.count == 0
          DatasetDownloadTally.create(tally: 1, download_date: Date.current, dataset_key: dataset.key, doi: dataset.identifier)
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

        today_datatafile_download_relation = FileDownloadTally.where(["file_web_id = ? and download_date = ?", self.web_id, Date.current])

        if today_datatafile_download_relation.count == 1
          today_file_download = today_datatafile_download_relation.first
          today_file_download.tally = today_file_download.tally + 1
          today_file_download.save
        elsif today_datatafile_download_relation.count == 0
          FileDownloadTally.create(tally: 1, download_date: Date.current, dataset_key: dataset.key, doi: dataset.identifier, file_web_id: self.web_id, filename: self.bytestream_name)
        else
          Rails.logger.warn "unexpected number of file tally records for download of #{self.web_id} on #{Date.current} from #{request_ip}"
        end

      end

    end

  end

  def remove_directory


    if self.storage_key && self.storage_key[0,3] == 'tus'
      key_parts = self.storage_key.split('/')
      name_part = key_parts[-1]
      begin
        Application.storage_manager.draft_root.delete_content("tus/#{name_part}.info")
      rescue StandardError => err
        Rails.logger.warn("remove error 1: #{err.message}")
      end

    end

    if self.storage_key && self.storage_key !=''
      begin
        Application.storage_manager.draft_root.delete_content(self.storage_key)
      rescue StandardError => err
        Rails.logger.warn("remove error 2: #{err.message}")
      end

      #Application.storage_manager.draft_root.delete_tree(self.web_id)
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

  # def chmod_binary_for_medusa
  #   if self.binary && self.binary.file
  #     FileUtils.chmod "u=wrx,go=rx", File.dirname(self.binary.path)
  #     FileUtils.chmod "u=wrx,go=rx", self.binary.path
  #
  #   end
  # end

end
