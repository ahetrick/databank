json.array!(@datasets) do |dataset|
  json.extract! dataset, :id, :title, :identifier, :publisher, :publication_year, :creator_list, :description, :rights
  json.url dataset_url(dataset, format: :json)
end
