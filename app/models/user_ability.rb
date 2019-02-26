class UserAbility < ActiveRecord::Base
  belongs_to :dataset
  validates_presence_of :dataset_id
end
