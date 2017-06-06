class Recordfile < ActiveRecord::Base

  include Viewable
  mount_uploader :binary, BinaryUploader
  belongs_to :dataset

  WEB_ID_LENGTH = 5
  before_create { self.web_id ||= generate_web_id }
  before_destroy 'remove_directory'

  def to_param
    self.web_id
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

  def bytestream_path
    if self.medusa_path.nil? || self.medusa_path.empty?
      self.binary.path
    else
      "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{self.medusa_path}"
    end
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
