class RelatedMaterial < ActiveRecord::Base
  belongs_to :dataset
  audited associated_with: :dataset
end
