json.array!(@funders) do |funder|
  json.extract! funder, :id, :name, :identifier, :identifier_scheme, :grant, :dataset_id
  json.url funder_url(funder, format: :json)
end
