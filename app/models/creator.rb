class Creator < ActiveRecord::Base

  default_scope { order (:row_position)}

  PERSON = 0
  INSTITUTION = 1

  enum type: [:person, :institution]

end
