class Recordfile < ActiveRecord::Base
  include ActiveModel::Serialization
  mount_uploader :binary, BinaryUploader
  belongs_to :dataset

  WEB_ID_LENGTH = 5
  before_create { self.web_id ||= generate_web_id }
  before_destroy 'remove_directory'

  def to_param
    self.web_id
  end

  private

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

  def remove_directory
    dir = "#{IDB_CONFIG[:datafile_store_dir]}/#{self.web_id}"
    if Dir.exists? dir
      FileUtils.rm_rf(dir)
    end
  end

end
