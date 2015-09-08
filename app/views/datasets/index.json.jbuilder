json.array!(@datasets) do |dataset|
  json.extract! dataset, :id, :title, :identifier, :publisher, :publication_year, :creator_text, :description, :license
  json.url dataset_url(dataset, format: :json)
end
