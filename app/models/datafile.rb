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

  def file_extension
    filename_split = self.bytestream_name.split(".")

    if filename_split.count > 1 # otherwise cannot determine extension

      return filename_split.last

    else
      return ""

    end

  end

  def bytestream_path
    if self.medusa_path.nil? || self.medusa_path.empty?
      self.binary.path
    else
      "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{self.medusa_path}"
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

    extension = self.bytestream_name.split(".").last

    content_files_array = []

    if self.is_archive?
      case extension

        when 'zip'

          Zip::InputStream.open(self.bytestream_path) do |io|

            while (entry = io.get_next_entry)

              content_file_hash = {}
              content_path_array = entry.name.split("/")
              content_file_hash['content_filename']=content_path_array[-1]
              content_file_hash['num_bytes'] = entry.size

              FileMagic.open(:mime) do |fm|
                 fm_info = fm.io(entry.get_input_stream)
                 content_file_hash['file_format'] = (fm_info.split("; "))[0]
              end

              content_files_array.push(content_file_hash)

            end

          end


        when '7z'

          entry_list_text = `7za l "#{self.bytestream_path}"`

          entry_list_array = entry_list_text.split("\n")

          entry_list_array.each_with_index do |raw_entry, index|
            if index > 19  && index < (entry_list_array.length - 2) # first twenty lines are headers, last two lines are summary

              entry_array = raw_entry.strip.split " "

              if entry_array[-1]

                content_file_hash = {}

                content_path_array = (entry_array[-1]).split("/")

                content_file_hash['content_filename']=content_path_array[-1]

                entry_num_bytes = (raw_entry[25..39]).strip.to_i

                content_file_hash['num_bytes'] = entry_num_bytes

                content_file_hash['file_format'] = MIME::Types.type_for(content_file_hash['content_filename']).first.content_type

                content_files_array.push(content_file_hash)

              end


            end
          end


        when 'gz'

          tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(self.bytestream_path))
          tar_extract.rewind # The extract has to be rewinded after every iteration
          tar_extract.each do |entry|

            if entry.file?

              content_file_hash = {}
              content_path_array = (entry.full_name).split("/")
              content_file_hash['content_filename']=content_path_array[-1]
              content_file_hash['num_bytes'] = entry.bytes_read
              FileMagic.open(:mime) do |fm|
                fm_info = fm.io(entry.read)
                content_file_hash['file_format'] = (fm_info.split("; "))[0]
              end
              content_files_array.push(content_file_hash)

            end

          end
          tar_extract.close


        when 'tar'
          tar_extract = Gem::Package::TarReader.new(self.bytestream_path)
          tar_extract.rewind # The extract has to be rewinded after every iteration
          tar_extract.each do |entry|

            if entry.file?

              content_file_hash = {}
              content_path_array = (entry.full_name).split("/")
              content_file_hash['content_filename']=content_path_array[-1]
              content_file_hash['num_bytes'] = entry.bytes_read
              FileMagic.open(:mime) do |fm|
                fm_info = fm.io(entry.read)
                content_file_hash['file_format'] = (fm_info.split("; "))[0]
              end
              content_files_array.push(content_file_hash)

            end

          end
          tar_extract.close
        
      end

    end

    content_files_array

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
    dir = "#{IDB_CONFIG[:datafile_store_dir]}/#{self.web_id}"
    if Dir.exists? dir
      FileUtils.rm_rf(dir)
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
      break unless Datafile.find_by_web_id(proposed_id) || Recordfile.find_by_web_id(proposed_id)
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
