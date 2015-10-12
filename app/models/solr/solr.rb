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
        copyFields: [
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
