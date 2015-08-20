module Repository

  class Item < ActiveMedusa::Container

    include BytestreamOwner
    include Indexable

    WEB_ID_LENGTH = 5

    entity_class_uri 'http://databank.illinois.edu/definitions/v1/repository#Datafile'

    belongs_to :collection, class_name: 'Repository::Collection',
               rdf_predicate: Databank::NAMESPACE_URI +
                   Databank::RDFPredicates::IS_MEMBER_OF_COLLECTION,
               solr_field: Solr::Fields::COLLECTION

    has_many :bytestreams, class_name: 'Repository::Bytestream'

    property :full_text,
             type: :string,
             rdf_predicate: Databank::NAMESPACE_URI +
                 Databank::RDFPredicates::FULL_TEXT,
             solr_field: Solr::Fields::FULL_TEXT
    # The media type of the master bytestream. This duplicates the same
    # property on the master bytestream, but it's needed in order to make Solr
    # queries less awkward.
    property :media_type,
             type: :string,
             rdf_predicate: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#hasMimeType',
             solr_field: Solr::Fields::MEDIA_TYPE

    property :published,
             type: :boolean,
             rdf_predicate: Databank::NAMESPACE_URI +
                 Databank::RDFPredicates::PUBLISHED,
             solr_field: Solr::Fields::PUBLISHED

    property :web_id,
             type: :string,
             rdf_predicate: Databank::NAMESPACE_URI +
                 Databank::RDFPredicates::WEB_ID,
             solr_field: Solr::Fields::WEB_ID

    property :description,
             type: :string,
             rdf_predicate: 'http://purl.org/dc/terms/description',
             solr_field: Solr::Fields::DESCRIPTION

    property :title,
             type: :string,
             rdf_predicate: 'http://purl.org/dc/terms/title',
             solr_field: Solr::Fields::SINGLE_TITLE

    #validates :title, length: { minimum: 2, maximum: 200 }
    validates :web_id, length: { minimum: WEB_ID_LENGTH,
                                 maximum: WEB_ID_LENGTH }

    before_create { self.web_id = generate_web_id }

    def initialize(params = {})
      @published = true
      super
    end

    def ==(other)
      other.kind_of?(self.class) and self.uuid == other.uuid
    end

    def bytestreams
      Repository::Bytestream.where(Solr::Fields::PARENT_URI => self.repository_url)
    end

    ##
    # @return boolean True if any text was extracted; false if not
    #
    def extract_and_update_full_text
      if self.master_bytestream and self.master_bytestream.repository_url
        begin
          yomu = Yomu.new(self.master_bytestream.repository_url)
          self.full_text = yomu.text.force_encoding('UTF-8')
        rescue Errno::EPIPE
          # nothing we can do
          return false
        else
          return self.full_text.present?
        end
      end
      false
    end

    def to_s
      self.title || self.web_id
    end

    def to_param
      self.web_id
    end

    def reindex
      databank_predicates = Databank::RDFPredicates

      doc = base_solr_document
      doc[Solr::Fields::COLLECTION] = self.rdf_graph.any_object(databank_predicates::IS_MEMBER_OF_COLLECTION)
      doc[Solr::Fields::FULL_TEXT] = self.rdf_graph.any_object(databank_predicates::FULL_TEXT)
      doc[Solr::Fields::MEDIA_TYPE] = self.media_type
      doc[Solr::Fields::PUBLISHED] = self.rdf_graph.any_object(databank_predicates::PUBLISHED)
      doc[Solr::Fields::SINGLE_TITLE] = self.title
      doc[Solr::Fields::WEB_ID] = self.rdf_graph.any_object(databank_predicates::WEB_ID)
      date = self.rdf_graph.any_object(databank_predicates::DATE).to_s.strip
      doc[Solr::Fields::DATE] = normalized_date(date)

      Solr::Solr.client.add(doc)
      Solr::Solr.client.commit
    end

    private

    ##
    # Generates a guaranteed-unique web ID, of which there are
    # 36^WEB_ID_LENGTH available.
    #
    def generate_web_id
      proposed_id = nil
      while true
        proposed_id = (36 ** (WEB_ID_LENGTH - 1) +
            rand(36 ** WEB_ID_LENGTH - 36 ** (WEB_ID_LENGTH - 1))).to_s(36)
        break unless self.class.find_by_web_id(proposed_id)
      end
      proposed_id
    end

    ##
    # Tries to extract a date from an input string.
    #
    # @param date_str [String]
    # @return [DateTime, nil]
    #
    def normalized_date(date_str)
      if date_str.present?
        # if the string contains a 4 digit number, assume it's a year
        year = date_str.match(/[0-9]{4,}/)
        if year
          dt = DateTime.strptime(year.to_s, '%Y')
          return dt.iso8601 + 'Z'
          # TODO: extract months/days
        end
      end
      nil
    end

  end

end
