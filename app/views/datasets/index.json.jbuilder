json.array!(@datasets) do |dataset|
  json.extract! dataset, :key, :title, :identifier, :publication_state, :curator_hold
  json.url dataset_url(dataset, format: :json)
end
