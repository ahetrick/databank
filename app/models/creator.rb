class Creator < ActiveRecord::Base
  include ActiveModel::Serialization
  belongs_to :dataset

  validates :has_name

  audited except: [:row_order, :type_of, :identifier_scheme, :dataset_id, :institution_name], associated_with: :dataset

  default_scope { order (:row_position) }

  def as_json(options={})
    if self.institution_name && self.institution_name != ''
      super(:only => [:institution_name, :identifier, :is_contact, :row_position, :created_at, :updated_at])
    else
      super(:only => [:family_name, :given_name, :identifier, :is_contact, :row_position, :created_at, :updated_at])
    end

  end

  def display_name

    if self.institution_name && self.institution_name != ''
       return_text = "#{self.institution_name}"
    elsif self.given_name && self.given_name != '' && self.family_name && self.family_name != ''
        return_text = "#{self.given_name} #{self.family_name}"
    else
      raise("institution_name: #{institution_name}, given_name: #{given_name}, family_name: #{family_name}")
      #return_text  = 'University of Illinois at Urbana-Champaign'
    end

    return_text

  end

  def list_name

    if self.institution_name && self.institution_name != ''
      return_text = "#{self.institution_name}"
    elsif self.family_name && self.family_name != ''
      return_text = "#{self.family_name}"
      if self.given_name && self.given_name != ''
        return_text << ", #{self.given_name}"
      end
    else
      raise("institution_name: #{institution_name}, given_name: #{given_name}, family_name: #{family_name}")
      #return_text  = 'University of Illinois at Urbana-Champaign'
    end
    return_text
  end

  def has_name
    unless (self.institution_name && self.institution_name != '') || (self.given_name && self.given_name != '' && self.family_name && self.family_name != '')
      errors.add([:base], "Creator must have a valid name.")
    end
  end


end
