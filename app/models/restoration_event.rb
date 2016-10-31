class RestorationEvent < ActiveRecord::Base
  has_many :restoration_id_maps, dependent: :destroy
end
