json.array!(@creators) do |creator|
  json.extract! creator, :id, :dataset_id, :family_name, :given_name, :institution_name, :identifier, :type, :row_order
  json.url creator_url(creator, format: :json)
end
