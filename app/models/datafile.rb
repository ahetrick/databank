class Datafile < ActiveRecord::Base
  include ActiveModel::Serialization
  mount_uploader :binary, BinaryUploader
  belongs_to :dataset
  audited associated_with: :dataset

  WEB_ID_LENGTH = 5

  before_create { self.web_id ||= generate_web_id }

  before_destroy 'destroy_job'
  before_destroy 'remove_directory'

  after_save 'chmod_binary_for_medusa'

  def to_param
    self.web_id
  end

  def as_json(options={})
    super(:only => [:web_id, :binary_name, :binary_size, :medusa_id, :created_at, :updated_at])
  end

  def bytestream_name
    return_name = ""
    if self.binary_name && self.binary_name != ""
      return_name = self.binary_name
    elsif self.binary && self.binary.file
      return_name = self.binary.file.filename
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

  def bytestream_path
    if self.medusa_path.nil? || self.medusa_path.empty?
      self.binary.path
    else
      "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{self.medusa_path}"
    end
  end

  def ip_downloaded_file_today(request_ip)
    DayFileDownload.where(["ip_address = ? and file_web_id = ? and download_date = ?", request_ip, self.web_id, Date.current]).count > 0
  end

  def record_download(request_ip)

    unless dataset.ip_downloaded_dataset_today(request_ip)

      today_dataset_download = DatasetDownloadTally.find_or_create_by(download_date: Date.current)
      
      if today_dataset_download.tally
        today_dataset_download.tally = today_dataset_download.tally + 1
        today_dataset.download.save
      else
        today_dataset_download.tally = 1
        today_dataset_download.dataset_key = dataset.key
        today_dataset_download.doi = dataset.identifier
        today_dataset_download.save
      end


    end

    unless ip_downloaded_file_today(request_ip)


      dataset = Dataset.find(self.dataset_id)

      if dataset && dataset.identifier # ignore draft datasets
        DayFileDownload.create(ip_address: request_ip,
                               download_date: Date.current,
                               file_web_id: self.web_id,
                               filename: self.bytestream_name,
                               dataset_key: dataset.key,
                               doi: dataset.identifier)

        today_file_download = FileDownloadTally.find_or_create_by(download_date: Date.current)

        if today_file_download.tally
          today_file_download.tally = today_file_download.tally + 1
          today_file_download.save
        else
          today_file_download.tally = 1
          today_file_download.dataset_key = dataset.key
          today_file_download.doi = dataset.identifier
          today_file_download.file_web_id = self.web_id
          today_file_download.filename = self.bytestream_name
          today_file_download.save
        end

      end

    end
  end

  def remove_directory
    dir = "#{IDB_CONFIG[:datafile_store_dir]}/#{self.web_id}"
    if Dir.exists? dir
      FileUtils.remove_dir(dir)
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
      break unless self.class.find_by_web_id(proposed_id)
    end
    proposed_id
  end

  def chmod_binary_for_medusa
    if self.binary && self.binary.file
      FileUtils.chmod "u=wrx,go=rx", File.dirname(self.binary.path)
      FileUtils.chmod "u=wrx,go=rx", self.binary.path

    end
  end

end
