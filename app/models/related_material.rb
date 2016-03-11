class RelatedMaterial < ActiveRecord::Base
  belongs_to :dataset
  audited associated_with: :dataset
  def as_json(options={})
    super(:only => [:material_type,:availability,:link,:uri,:uri_type,:citation,:dataset_id,:created_at,:updated_at] )
  end
end
