module Solr

  class Solr

    ##
    # Schema summary:
    #
    # uri_*_txt          arbitrary RDF objects
    # idb_meta_*          normalized metadata schema into which many of the
    #                    uri_* fields are copied (notably, /dc/elements/1.1 and
    #                    /dc/terms are merged)
    # idb_meta_title_s    Single-valued title field that can be sorted (must be
    #                    populated manually)
    # idb_meta_date_dts   Single-valued date field
    # idb_sys_*           system properties
    # idb_*_facet         facets
    # idb_searchall_txt   full-text search field
    #
    # There are no classic fields, only dynamicFields and copyFields.
    #
    # The values of this hash will be POSTed as-is to Solr's schema API
    # endpoint.
    #
    SCHEMA = {
        copyFields: [ # TODO: replace these with a "normalized fields" feature
            # Map various fields to Databank's own schema. The main purpose
            # of this is to normalize the DC elements and terms.
            {
                source: 'uri_http_purl_org_dc_elements_1_1_contributor_txt',
                dest: 'idb_meta_contributor_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_coverage_txt',
                dest: 'idb_meta_coverage_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_creator_txt',
                dest: 'idb_meta_creator_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_date_txt',
                dest: 'idb_meta_date_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_description_txt',
                dest: 'idb_meta_description_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_format_txt',
                dest: 'idb_meta_format_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_identifier_s',
                dest: 'idb_meta_identifier_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_language_txt',
                dest: 'idb_meta_language_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_publisher_txt',
                dest: 'idb_meta_publisher_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_relation_txt',
                dest: 'idb_meta_relation_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_rights_txt',
                dest: 'idb_meta_rights_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_source_txt',
                dest: 'idb_meta_source_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_subject_txt',
                dest: 'idb_meta_subject_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_title_txt',
                dest: 'idb_meta_title_txt'
            },
            {
                source: 'uri_http_purl_org_dc_elements_1_1_type_txt',
                dest: 'idb_meta_type_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_abstract_txt',
                dest: 'idb_meta_abstract_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_accessRights_txt',
                dest: 'idb_meta_accessRights_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_accrualMethod_txt',
                dest: 'idb_meta_accrualMethod_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_accrualPeriodicity_txt',
                dest: 'idb_meta_accrualPeriodicity_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_accrualPolicy_txt',
                dest: 'idb_meta_accrualPolicy_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_alternative_txt',
                dest: 'idb_meta_alternative_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_audience_txt',
                dest: 'idb_meta_audience_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_available_txt',
                dest: 'idb_meta_available_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_bibliographicCitation_txt',
                dest: 'idb_meta_bibliographicCitation_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_conformsTo_txt',
                dest: 'idb_meta_conformsTo_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_contributor_txt',
                dest: 'idb_meta_contributor_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_coverage_txt',
                dest: 'idb_meta_coverage_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_created_txt',
                dest: 'idb_meta_created_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_creator_txt',
                dest: 'idb_meta_creator_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_date_txt',
                dest: 'idb_meta_date_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_dateAccepted_txt',
                dest: 'idb_meta_dateAccepted_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_dateCopyrighted_txt',
                dest: 'idb_meta_dateCopyrighted_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_dateSubmitted_txt',
                dest: 'idb_meta_dateSubmitted_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_description_txt',
                dest: 'idb_meta_description_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_educationLevel_txt',
                dest: 'idb_meta_educationLevel_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_extent_txt',
                dest: 'idb_meta_extent_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_format_txt',
                dest: 'idb_meta_format_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_hasFormat_txt',
                dest: 'idb_meta_hasFormat_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_hasPart_txt',
                dest: 'idb_meta_hasPart_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_hasVersion_txt',
                dest: 'idb_meta_hasVersion_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_identifier_txt',
                dest: 'idb_meta_identifier_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_instructionalMethod_txt',
                dest: 'idb_meta_instructionalMethod_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_isFormatOf_txt',
                dest: 'idb_meta_isFormatOf_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_isPartOf_txt',
                dest: 'idb_meta_isPartOf_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_isReferencedBy_txt',
                dest: 'idb_meta_isReferencedBy_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_isReplacedBy_txt',
                dest: 'idb_meta_isReplacedBy_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_isRequiredBy_txt',
                dest: 'idb_meta_isRequiredBy_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_issued_txt',
                dest: 'idb_meta_issued_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_isVersionOf_txt',
                dest: 'idb_meta_language_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_language_txt',
                dest: 'idb_meta_language_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_license_txt',
                dest: 'idb_meta_license_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_mediator_txt',
                dest: 'idb_meta_mediator_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_MediaType_txt',
                dest: 'idb_sys_media_type_s'
            },
            {
                source: 'uri_http_purl_org_dc_terms_medium_txt',
                dest: 'idb_meta_medium_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_modified_txt',
                dest: 'idb_meta_modified_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_provenance_txt',
                dest: 'idb_meta_provenance_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_publisher_txt',
                dest: 'idb_meta_publisher_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_references_txt',
                dest: 'idb_meta_references_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_relation_txt',
                dest: 'idb_meta_relation_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_replaces_txt',
                dest: 'idb_meta_replaces_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_requires_txt',
                dest: 'idb_meta_requires_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_rights_txt',
                dest: 'idb_meta_rights_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_rightsHolder_txt',
                dest: 'idb_meta_rightsHolder_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_source_txt',
                dest: 'idb_meta_source_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_spatial_txt',
                dest: 'idb_meta_spatial_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_subject_txt',
                dest: 'idb_meta_subject_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_tableOfContents_txt',
                dest: 'idb_meta_tableOfContents_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_temporal_txt',
                dest: 'idb_meta_temporal_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_title_txt',
                dest: 'idb_meta_title_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_type_txt',
                dest: 'idb_meta_type_txt'
            },
            {
                source: 'uri_http_purl_org_dc_terms_valid_txt',
                dest: 'idb_meta_valid_txt'
            }
        ],
        dynamicFields: [
            {
                name: '*_facet',
                type: 'string',
                stored: true,
                indexed: true,
                multiValued: true,
                docValues: true
            }
        ]
    }

    @@client = RSolr.connect(url: IDB_CONFIG[:solr_url].chomp('/') +
                                 '/' + IDB_CONFIG[:solr_core])

    ##
    # @return [RSolr]
    #
    def self.client
      @@client
    end

    ##
    # Gets the Solr-compatible field name for a given predicate.
    #
    # @param predicate [String]
    #
    def self.field_name_for_predicate(predicate)
      # convert all non-alphanumerics to underscores and then replace
      # repeating underscores with a single underscore
      'uri_' + predicate.to_s.gsub(/[^0-9a-z ]/i, '_').gsub(/\_+/, '_') + '_txt'
    end

    def initialize
      @http = HTTPClient.new
      @url = IDB_CONFIG[:solr_url].chomp('/') + '/' +
          IDB_CONFIG[:solr_core]
    end

    def clear
      @http = HTTPClient.new
      @http.get(@url + '/update?stream.body=<delete><query>*:*</query></delete>')
      @http.get(@url + '/update?stream.body=<commit/>')
    end

    ##
    # @param term [String] Search term
    # @return [Array] String suggestions
    #
    def suggestions(term)
      result = Solr::client.get('suggest', params: { q: term })
      suggestions = result['spellcheck']['suggestions']
      suggestions.any? ? suggestions[1]['suggestion'] : []
    end

    ##
    # Creates the set of fields needed by the application. This requires
    # Solr 5.2+ with the ManagedIndexSchemaFactory enabled.
    #
    # @return [HTTP::Message, nil] Nil if there were no fields to create.
    #
    def update_schema
      # Solr will throw an error if we try to add a field that already exists,
      # so we have to send it only fields that don't already exist.
      response = @http.get("#{@url}/schema")
      current = JSON.parse(response.body)

      # dynamic fields
      dynamic_fields_to_add = SCHEMA[:dynamicFields].reject do |kf|
        current['schema']['dynamicFields'].
            map{ |sf| sf['name'] }.include?(kf[:name])
      end
      post_fields('add-dynamic-field', dynamic_fields_to_add)

      # copy faceted triples into facet fields
      facetable_fields = Triple.where('facet_id IS NOT NULL').
          uniq(&:predicate).map do |t|
        { source: self.class.field_name_for_predicate(t.predicate),
          dest: t.facet.solr_field }
      end

      facetable_fields_to_add = facetable_fields.reject do |ff|
        current['schema']['copyFields'].
            map{ |sf| "#{sf['source']}-#{sf['dest']}" }.
            include?("#{ff[:source]}-#{ff[:dest]}")
      end
      post_fields('add-copy-field', facetable_fields_to_add)

      # copy various fields into a search-all field
      search_all_fields_to_add = search_all_fields.reject do |ff|
        current['schema']['copyFields'].
            map{ |sf| "#{sf['source']}-#{sf['dest']}" }.
            include?("#{ff[:source]}-#{ff[:dest]}")
      end
      post_fields('add-copy-field', search_all_fields_to_add)

      # other copyFields
      copy_fields_to_add = SCHEMA[:copyFields].reject do |kf|
        current['schema']['copyFields'].
            map{ |sf| "#{sf['source']}-#{sf['dest']}" }.
            include?("#{kf[:source]}-#{kf[:dest]}")
      end
      post_fields('add-copy-field', copy_fields_to_add)
    end

    private

    ##
    # @param key [String]
    # @param fields [Array]
    #
    def post_fields(key, fields)
      if fields.any?
        json = JSON.generate({ key => fields })
        response = @http.post("#{@url}/schema", json,
                             { 'Content-Type' => 'application/json' })
        message = JSON.parse(response.body)
        if message['errors']
          raise "Failed to update Solr schema: #{message['errors']}"
        end
      end
    end

    ##
    # Returns a list of fields that will be copied into a "search-all" field
    # for easy searching.
    #
    # @return [Array] Array of strings
    #
    def search_all_fields
      dest = 'idb_searchall_txt'
      fields = Triple.all.uniq(&:predicate).map do |t|
        { source: self.class.field_name_for_predicate(t.predicate),
          dest: dest }
      end
      fields << { source: 'idb_sys_full_text_txt', dest: dest }
      fields
    end

  end

end
