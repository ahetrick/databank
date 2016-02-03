json.array!(@funder_infos) do |funder_info|
  json.extract! funder_info, :id, :code, :name, :identifier, :display_position, :identifier_scheme
  json.url funder_info_url(funder_info, format: :json)
end
