class Binary < ActiveRecord::Base
  mount_uploader :datafile, DatafileUploader
  belongs_to :dataset

end
