class Contributor < ActiveRecord::Base
  include ActiveModel::Serialization
  belongs_to :dataset
  audited except: [:row_order, :type_of, :identifier_scheme, :dataset_id, :institution_name], associated_with: :dataset

  default_scope { order (:row_position) }

  def as_json(options={})
    super(:only => [:family_name, :given_name, :identifier, :row_position, :created_at, :updated_at])
  end

  def display_name

    return_text = "placeholder name"

    if self.type_of == Databank::CreatorType::INSTITUTION
      return_text = "#{self.institution_name}"
    else
      return_text = "#{self.given_name} #{self.family_name}"
    end

  end
end
