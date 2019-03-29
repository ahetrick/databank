class Contributor < ActiveRecord::Base
  include ActiveModel::Serialization
  belongs_to :dataset
  audited except: [:row_order, :type_of, :identifier_scheme, :dataset_id, :institution_name], associated_with: :dataset

  default_scope { order (:row_position) }

  def as_json(options={})
    super(:only => [:family_name, :given_name, :identifier, :row_position, :created_at, :updated_at])
  end

  def display_name
    if self.type_of == Databank::CreatorType::INSTITUTION
      "#{self.institution_name}"
    else
      "#{self.given_name} #{self.family_name}"
    end
  end

  def list_name
    return_text = ""
    if self.family_name && self.family_name != ''
      return_text = "#{self.family_name}"
      if self.given_name && self.given_name != ''
        return_text << ", #{self.given_name}"
      end
    elsif self.given_name && self.given_name != ''
      return_text = "#{self.given_name}"
    end
    return_text
  end

end
