json.array!(@binaries) do |binary|
  json.extract! binary, :id, :attachment, :dataset_id
  json.url binary_url(binary, format: :json)
end
