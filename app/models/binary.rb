class Binary < ActiveRecord::Base
  mount_uploader :attachment, AttachmentUploader
  belongs_to :dataset
end
