require_relative 'databank'

ActiveMedusa::Configuration.new do |config|
  databank_config = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]
  config.fedora_url = databank_config[:fedora_url]
  config.logger = Rails.logger
  config.class_predicate = Databank::NAMESPACE_URI + Databank::RDFPredicates::CLASS
  config.solr_url = databank_config[:solr_url]
  config.solr_core = databank_config[:solr_core]
  # config.solr_more_like_this_endpoint = '/mlt'
  config.solr_class_field = Solr::Fields::CLASS
  config.solr_id_field = :id
  config.solr_default_search_field = Solr::Fields::SEARCH_ALL
  config.solr_parent_uri_field = Solr::Fields::PARENT_URI
  # config.solr_default_facetable_fields is set in an after_initialize hook in
  # application.rb; can't be done here as ActiveRecord hasn't been initialized
  # yet
end