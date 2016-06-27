json.array!(@deckfiles) do |deckfile|
  json.extract! deckfile, :id, :disposition, :remove, :path, :dataset_id
  json.url deckfile_url(deckfile, format: :json)
end
