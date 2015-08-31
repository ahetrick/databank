module Repository

# collection.rb
  class Collection < ActiveMedusa::Container

    include ActiveMedusa::Indexable
    include Introspection

    entity_class_uri 'http://databank.illinois.edu/definitions/v1/repository#Dataset'

    has_many :items, class_name: 'Repository::Item'

    property :key,
             type: :string,
             rdf_predicate: Databank::NAMESPACE_URI +
                 Databank::RDFPredicates::COLLECTION_KEY,
             solr_field: Solr::Fields::COLLECTION_KEY

    property :published,
             type: :boolean,
             rdf_predicate: Databank::NAMESPACE_URI +
                 Databank::RDFPredicates::PUBLISHED,
             solr_field: Solr::Fields::PUBLISHED

    property :title,
             type: :string,
             rdf_predicate: 'http://purl.org/dc/terms/title',
             solr_field: Solr::Fields::SINGLE_TITLE

    property :creator_list,
             type: :string,
             rdf_predicate: 'http://purl.org/dc/terms/creator',
             solr_field: Solr::Fields::CREATOR_LIST

    property :description,
             type: :string,
             rdf_predicate: 'http://purl.org/dc/terms/description',
             solr_field: Solr::Fields::DESCRIPTION

    property :identifier,
             type: :string,
             rdf_predicate: 'http://purl.org/dc/terms/identifier',
             solr_field: Solr::Fields::IDENTIFIER

    property :license,
             type: :string,
             rdf_predicate: 'http://purl.org/dc/terms/license',
             solr_field: Solr::Fields::LICENSE

    property :publication_year,
             type: :string,
             rdf_predicate: 'http://purl.org/dc/terms/issued',
             solr_field: Solr::Fields::PUBLICATION_YEAR

    property :publisher,
             type: :string,
             rdf_predicate: 'http://purl.org/dc/terms/publisher',
             solr_field: Solr::Fields::PUBLISHER

    def reindex

      Rails.logger.info "Description:"

      Rails.logger.info self.description

      databank_predicates = Databank::RDFPredicates

      doc = base_solr_document
      doc[Solr::Fields::COLLECTION_KEY] = self.rdf_graph.any_object(databank_predicates::COLLECTION_KEY)
      doc[Solr::Fields::PUBLISHED] =  self.rdf_graph.any_object(databank_predicates::PUBLISHED)
      doc[Solr::Fields::SINGLE_TITLE] = self.title
      doc[Solr::Fields::CREATOR_LIST] = self.creator_list
      doc[Solr::Fields::DESCRIPTION] = self.description
      doc[Solr::Fields::IDENTIFIER] = self.identifier
      doc[Solr::Fields::LICENSE] = self.license
      doc[Solr::Fields::PUBLICATION_YEAR] = self.publication_year
      doc[Solr::Fields::PUBLISHER] = self.publisher

      Solr::Solr.client.add(doc)
      Solr::Solr.client.commit
    end


  end
end