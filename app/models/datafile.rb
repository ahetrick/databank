require 'zip'
require 'seven_zip_ruby'
require 'filemagic'
require 'mime/types'
require 'minitar'
require 'zlib'


class Datafile < ActiveRecord::Base
  include ActiveModel::Serialization
  include Viewable
  belongs_to :dataset
  has_many :nested_items, dependent: :destroy
  audited associated_with: :dataset

  WEB_ID_LENGTH = 5

  before_create { self.web_id ||= generate_web_id }

  before_destroy 'destroy_job'
  before_destroy 'remove_binary'

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
    self.binary_name
  end

  def bytestream_size

    if self.current_root
      self.current_root.size(self.storage_key)
    else
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
      self.current_root.real_path
    end
  end

  # within the context of the databank server mounts
  def filepath
    base = self.storage_root_path
    if base
      File.join(base, "key")
    else
      raise("no filesystem path found for datafile: #{self.web_id}")
    end
  end

  # medusa mounts are different on iiif server
  def iiif_bytestream_path
    if self.storage_root == 'draft'
      self.filepath
    elsif self.storage_root == 'medusa'
      "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{IDB_CONFIG[:iiif_medusa_group]}/#{self.storage_key}"
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

    if dataset&.identifier && dataset.identifier != "" # ignore draft datasets

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
    current_root.delete_content(self.storage_key)
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

end
