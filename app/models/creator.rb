class Creator < ActiveRecord::Base
  belongs_to :dataset
  audited except: [:row_order, :type_of, :identifier_scheme, :dataset_id, :institution_name], associated_with: :dataset

  default_scope { order (:row_position)}

  PERSON = 0
  INSTITUTION = 1

  enum type: [:person, :institution]

  def as_json(options={})
    super(:only => [:family_name,:given_name,:identifier,:is_contact,:row_position,:created_at,:updated_at] )
  end

end
