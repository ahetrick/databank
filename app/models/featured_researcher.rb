class FeaturedResearcher < ActiveRecord::Base
  mount_uploader :binary, BinaryUploader

  def web_id
    "photo_#{self.id}"
  end

end
