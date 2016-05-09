class RelatedMaterial < ActiveRecord::Base
  include ActiveModel::Serialization
  belongs_to :dataset
  audited associated_with: :dataset

  def as_json(options={})
    super(:only => [:material_type, :availability, :link, :uri, :uri_type, :citation, :dataset_id, :created_at, :updated_at])
  end

  def relationship_arr
    if self.datacite_list && self.datacite_list != ''
      return self.datacite_list.split(',')
    else
      return Array.new
    end

  end

end
