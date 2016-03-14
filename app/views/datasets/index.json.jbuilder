json.array!(@datasets) do |dataset|
  if [Databank::PublicationState::RELEASED, Databank::PublicationState::FILE_EMBARGO, Databank::PublicationState::TOMBSTONE].include? dataset.publication_state
    json.extract! dataset, :identifier, :publication_state, :curator_hold, :created_at, :updated_at, :plain_text_citation
    json.url dataset_url(dataset, format: :json)
  elsif [Databank::PublicationState::METADATA_EMBARGO, Databank::PublicationState::DRAFT].include? dataset.publication_state
    json.extract! dataset, :identifier, :publication_state, :curator_hold, :created_at, :updated_at
    json.plain_text_citation "unavailable"
    json.url dataset_url(dataset, format: :json)
  end
end
