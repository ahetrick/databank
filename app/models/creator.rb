class Creator < ActiveRecord::Base

  include RankedModel

  belongs_to :dataset

  ranks :row_order,
      :with_same => :dataset_id

  default_scope { order (:row_order)}

  PERSON = 0
  INSTITUTION = 1

  enum type: [:person, :institution]
end
