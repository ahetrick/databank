if [Databank::PublicationState::RELEASED, Databank::PublicationState::Embargo::FILE, Databank::PublicationState::PermSupress::FILE].include? @dataset.publication_state
  json.extract! @dataset, :title, :identifier, :publisher, :publication_year, :description, :license, :corresponding_creator_name, :created_at, :updated_at, :keywords, :has_datacite_change, :publication_state, :version, :hold_state, :release_date, :embargo, :is_test, :is_import, :tombstone_date, :creators, :funders, :related_materials, :datafiles
  json.url dataset_url(@dataset, format: :json)
else
  json.url dataset_url(@dataset, format: :json)
  json.metadata "unavailable"
end