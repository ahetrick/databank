class Funder < ActiveRecord::Base
  include ActiveModel::Serialization
  belongs_to :dataset
  audited associated_with: :dataset

  def as_json(options={})
    super(:only => [:name, :identifier, :identifier_scheme, :grant, :created_at, :updated_at])
  end
end
