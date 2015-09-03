module Repository

  class Bytestream < ActiveMedusa::Binary

    include ActiveMedusa::Indexable

    class Type
      DERIVATIVE = Databank::NAMESPACE_URI +
          Databank::RDFObjects::DERIVATIVE_BYTESTREAM
      MASTER = Databank::NAMESPACE_URI + Databank::RDFObjects::MASTER_BYTESTREAM
    end

    entity_class_uri Databank::NAMESPACE_URI + Databank::RDFObjects::BYTESTREAM

    belongs_to :datafile, class_name: 'Repository::Datafile',
               rdf_predicate: Databank::NAMESPACE_URI +
                   Databank::RDFPredicates::IS_MEMBER_OF_DATAFILE,
               solr_field: Solr::Fields::DATAFILE

    property :height,
             type: :integer,
             rdf_predicate: Databank::NAMESPACE_URI +
                 Databank::RDFPredicates::HEIGHT,
             solr_field: Solr::Fields::HEIGHT

    property :media_type,
             type: :string,
             rdf_predicate: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#hasMimeType',
             solr_field: Solr::Fields::MEDIA_TYPE

    property :type,
             type: :anyURI,
             rdf_predicate: Databank::NAMESPACE_URI +
                 Databank::RDFPredicates::BYTESTREAM_TYPE,
             solr_field: Solr::Fields::BYTESTREAM_TYPE

    property :width,
             type: :integer,
             rdf_predicate: Databank::NAMESPACE_URI +
                 Databank::RDFPredicates::WIDTH,
             solr_field: Solr::Fields::WIDTH

    property :pcdm_class,
             type: :string,
             rdf_predicate: 'http://www.w3.org/2000/01/rdf-schema#Class',
             solr_field: Solr::Fields::PCDM_CLASS

    before_save :assign_technical_info
    before_create :set_pcdm_class

    def set_pcdm_class
      self.pcdm_class = 'http://pcdm.org/models#File'
    end

    ##
    # Returns the PREMIS byte size, populated by the repository. Not available
    # until the instance has been persisted.
    #
    # @return [Integer]
    #
    def byte_size
      self.rdf_graph.any_object('http://www.loc.gov/premis/rdf/v1#hasSize').to_i
    end

    ##
    # Returns the fedora filename. Not available until the instance has been
    # persisted.  This triple may not be visible in the web interface.
    #
    # @return [String]
    #
    def filename
      self.rdf_graph.any_object('http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#filename').to_s
    end

    def guess_media_type
      type = nil
      if self.upload_pathname and File.exist?(self.upload_pathname)
        type = MIME::Types.of(self.upload_pathname).first.to_s
      elsif self.external_resource_url
        type = MIME::Types.of(self.external_resource_url).first.to_s
      end
      self.media_type = type if type
    end

    def is_audio?
      self.media_type and self.media_type.start_with?('audio/')
    end

    def is_image?
      self.media_type and self.media_type.start_with?('image/')
    end

    def is_pdf?
      self.media_type and self.media_type == 'application/pdf'
    end

    def is_text?
      self.media_type and self.media_type.start_with?('text/')
    end

    def is_video?
      self.media_type and self.media_type.start_with?('video/')
    end

    ##
    # Reads the width and height (if an image) and assigns them to the instance.
    # Only works for images.
    #
    def read_dimensions
      if self.is_image?
        if self.upload_pathname
          read_dimensions_from_pathname(self.upload_pathname)
        elsif self.external_resource_url
          response = ActiveMedusa::Fedora.client.get(self.external_resource_url)
          tempfile = Tempfile.new('tmp')
          tempfile.write(response.body)
          tempfile.close
          read_dimensions_from_pathname(tempfile.path)
          tempfile.unlink
        end
      end
    end

    def to_param
      self.id
    end

    def reindex
      databank_predicates = Databank::RDFPredicates

      doc = base_solr_document
      doc[Solr::Fields::DATAFILE] =
          self.rdf_graph.any_object(databank_predicates::IS_MEMBER_OF_DATAFILE)
      doc[Solr::Fields::BYTE_SIZE] = self.byte_size
      doc[Solr::Fields::MEDIA_TYPE] = self.media_type
      doc[Solr::Fields::BYTESTREAM_TYPE] = self.type
      doc[Solr::Fields::PCDM_CLASS] = self.pcdm_class
      Solr::Solr.client.add(doc)
      Solr::Solr.client.commit

    end

    private

    def assign_technical_info
      self.guess_media_type unless self.media_type
      self.read_dimensions unless self.width and self.height
    end

    ##
    # @param pathname string
    # @return void
    #
    def read_dimensions_from_pathname(pathname)
      glue = '|'
      output = `identify -format "%[fx:w]#{glue}%[fx:h]" #{pathname}`
      parts = output.split(glue)
      if parts.length == 2
        self.width = parts[0].strip.to_i
        self.height = parts[1].strip.to_i
      end
    end

  end

end
