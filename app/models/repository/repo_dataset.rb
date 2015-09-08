module Repository

  class RepoDataset < ActiveMedusa::Container

    include ActiveMedusa::Indexable
    include Introspection

    entity_class_uri Databank::NAMESPACE_URI + Databank::RDFObjects::DATASET

    has_many :datafiles, class_name: 'Repository::Datafile'

    property :key,
             type: :string,
             rdf_predicate: Databank::NAMESPACE_URI +
                 Databank::RDFPredicates::DATASET_KEY,
             solr_field: Solr::Fields::DATASET_KEY

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

    property :pcdm_class,
             type: :string,
             rdf_predicate: 'http://www.w3.org/2000/01/rdf-schema#Class',
             solr_field: Solr::Fields::PCDM_CLASS

    before_create :set_pcdm_class

    def set_pcdm_class
      self.pcdm_class = 'http://pcdm.org/models#Object'
    end

    def reindex

      doc = base_solr_document
      doc[Solr::Fields::DATASET_KEY] = self.rdf_graph.any_object(Databank::RDFPredicates::DATASET_KEY)
      doc[Solr::Fields::PUBLISHED] =  self.rdf_graph.any_object(Databank::RDFPredicates::PUBLISHED)
      doc[Solr::Fields::SINGLE_TITLE] = self.title
      doc[Solr::Fields::CREATOR_LIST] = self.creator_list
      doc[Solr::Fields::DESCRIPTION] = self.description
      doc[Solr::Fields::IDENTIFIER] = self.identifier
      doc[Solr::Fields::LICENSE] = self.license
      doc[Solr::Fields::PUBLICATION_YEAR] = self.publication_year
      doc[Solr::Fields::PUBLISHER] = self.publisher
      doc[Solr::Fields::PCDM_CLASS] = self.pcdm_class

      Solr::Solr.client.add(doc)
      Solr::Solr.client.commit
    end


  end
end