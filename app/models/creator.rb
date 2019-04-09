# frozen_string_literal: true

# represents a creator as defined in DataCite metadata schema
class Creator < ActiveRecord::Base
  include ActiveModel::Serialization
  belongs_to :dataset
  validate :name?

  audited except: %i[row_order
                     type_of
                     identifier_scheme
                     dataset_id
                     institution_name], associated_with: :dataset

  default_scope { order(:row_position) }

  def as_json(*)
    if institution_name && institution_name != ''
      super(only: %i[institution_name
                     identifier
                     is_contact
                     row_position
                     created_at
                     updated_at])
    else
      super(only: %i[family_name
                     given_name
                     identifier
                     is_contact
                     row_position
                     created_at
                     updated_at])
    end
  end

  def display_name
    if type_of == Databank::CreatorType::INSTITUTION
      institution_name.to_s
    else
      "#{given_name || ''} #{family_name || ''}"
    end
  end

  # text for the name when used in a list
  def list_name
    if type_of == Databank::CreatorType::INSTITUTION
      institution_name.to_s
    else
      "#{family_name || ''}, #{given_name || ''}"
    end
  end

  private

  # validation
  def name?
    unless (institution_name && institution_name != '') ||
           (given_name && given_name != '' && family_name && family_name != '')
      errors.add(:base, 'Creator must have a valid name.')
    end
  end
end
