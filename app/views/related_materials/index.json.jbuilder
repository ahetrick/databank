json.array!(@related_materials) do |related_material|
  json.extract! related_material, :id, :materialType, :availability, :link, :uri, :uri_type, :citation, :dataset_id
  json.url related_material_url(related_material, format: :json)
end
