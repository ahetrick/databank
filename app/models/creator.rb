class Creator < ActiveRecord::Base
  include ActiveModel::Serialization
  belongs_to :dataset
  audited except: [:row_order, :type_of, :identifier_scheme, :dataset_id, :institution_name], associated_with: :dataset

  default_scope { order (:row_position) }

  def as_json(options={})
    super(:only => [:family_name, :given_name, :identifier, :is_contact, :row_position, :created_at, :updated_at])
  end

  def display_name

    if self.type_of == Databank::CreatorType::INSTITUTION

      if self.institution_name && self.institution_name != ''
       return_text = "#{self.institution_name}"
      else
        return_text  = 'University of Illinois at Urbana-Champaign'
      end

    else

      if self.given_name && self.given_name != '' && self.family_name && self.family_name != ''
        return_text = "#{self.given_name} #{self.family_name}"
      else
        return_text  = 'University of Illinois at Urbana-Champaign'
      end
    end

    return_text

  end

  def list_name

    Rails.logger.warn self.to_yaml

    if self.type_of == Databank::CreatorType::INSTITUTION

      if self.institution_name && self.institution_name != ''
        return_text = "#{self.institution_name}"
      else
        return_text  = 'University of Illinois at Urbana-Champaign'
      end

    else

      if self.given_name && self.given_name != '' && self.family_name && self.family_name != ''
        return_text = "#{self.family_name}, #{self.given_name}"
      else
        return_text  = 'University of Illinois at Urbana-Champaign'
      end
    end

    return_text
  end

end
