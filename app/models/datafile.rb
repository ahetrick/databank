class Datafile < ActiveRecord::Base
  mount_uploader :binary, BinaryUploader
  # belongs_to :dataset

  WEB_ID_LENGTH = 5

  before_create { self.web_id ||= generate_web_id }

  before_destroy 'remove_directory'

  def to_param
    self.web_id
  end

  def remove_directory

    # Rails.logger.warn "#{IDB_CONFIG[:datafile_store_dir]}/#{self.web_id}"
    dir = "#{IDB_CONFIG[:datafile_store_dir]}/#{self.web_id}"
    if Dir.exists? dir
      FileUtils.remove_dir(dir)
    end
  end

  def job_status
    if self.job_id
      job = Delayed::Job.find(job_id)
      raise ActiveRecord::RecordNotFound unless job

      if job.locked_by.nil?
        return :pending
      else
        return :running
      end
    else
      return :complete
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

end
