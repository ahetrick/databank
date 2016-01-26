class Datafile < ActiveRecord::Base

  mount_uploader :binary, BinaryUploader
  belongs_to :dataset

  WEB_ID_LENGTH = 5

  before_create { self.web_id ||= generate_web_id }

  before_destroy 'destroy_job'
  before_destroy 'remove_directory'

  after_save 'chmod_binary_for_medusa'

  def to_param
    self.web_id
  end

  def bytestream_name
    if self.binary_name
      self.binary_name
    elsif self.binary && self.binary.file
      self.binary.file.filename
    else
      ""
    end

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

  def remove_directory
    # Rails.logger.warn "#{IDB_CONFIG[:datafile_store_dir]}/#{self.web_id}"
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
      FileUtils.chmod "u=wrx,go=r", self.binary.path
    end
  end

end
