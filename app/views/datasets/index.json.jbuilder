json.array!(@datasets) do |dataset|
  json.extract! dataset, :identifier, :key, :title,  :publication_state, :curator_hold
  json.url dataset_url(dataset, format: :json)
end
