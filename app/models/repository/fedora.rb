module Repository

  class Fedora

    # Predicate URIs that start with any of these are repository-managed...
    # not really, but we'll just say they are for now.
    MANAGED_PREDICATES = [
        'http://fedora.info/definitions/',
        'http://www.iana.org/assignments/relation',
        'http://www.jcp.org/jcr',
        'http://www.loc.gov/premis/rdf/v1#',
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        'http://www.w3.org/2000/01/rdf-schema#',
        'http://www.w3.org/ns/ldp#'
    ]

    def reindex
      # In case we are coming in via rake, we have to reference all of our
      # model classes before ActiveMedusa::Base.class_for_predicate will work
      [RepoDataset, Datafile, Bytestream]
      delete_missing_ids
      index_node(ActiveMedusa::Configuration.instance.fedora_url)
    end

    private

    def delete_ids(ids)
      if ids.any?
        Rails.logger.debug("Deleting #{ids} missing records from Solr")
        body = "<delete><query>#{Solr::Fields::ID}:(#{ids.to_a.join(' OR ')})</query></delete>"
        Solr::Solr.client.post('update', params: { 'stream.body' => body})
      end
    end

    ##
    # Gets a list of all node URIs from Solr and deletes any that
    # don't exist in the repository.
    #
    def delete_missing_ids
      chunk_size = 1000
      solr = Solr::Solr.client
      params = { q: '*:*', fl: Solr::Fields::ID, start: 0, rows: 0 }
      response = solr.get('select', params: params)
      num_results = response['response']['numFound'].to_i
      num_chunks = (num_results / chunk_size.to_f).ceil
      ids = Set.new
      num_chunks.times do |i|
        params[:rows] = chunk_size
        params[:start] = i * num_results
        response = Solr::Solr.client.get('select', params: params)
        response['response']['docs'].each do |doc|
          ids << doc[Solr::Fields::ID.to_s] unless
              exists_in_fedora?(doc[Solr::Fields::ID.to_s])
        end
      end
      delete_ids(ids)
    end

    def exists_in_fedora?(url)
      http = ActiveMedusa::Fedora.client
      begin
        http.head(url)
      rescue ActiveMedusa::RepositoryError => e
        return false if [404, 410].include?(e.res.status)
      end
      true
    end

    ##
    # Recursive method that indexes the node at the given URL and all of its
    # children.
    #
    # @param url [String]
    #
    def index_node(url)
      graph = fetch_graph(url)
      class_uri = graph.any_object(ActiveMedusa::Configuration.
                                       instance.class_predicate)
      if class_uri
        begin
          instance = ActiveMedusa::Base.load(url)
          instance.reindex
        rescue
          # noop
        end
      end

      # index its children
      graph.each_statement do |st|
        if st.predicate.to_s == 'http://www.w3.org/ns/ldp#contains'
          index_node(st.object.to_s)
        end
      end

      Solr::Solr.client.commit
    end

    def fetch_graph(url)
      http = ActiveMedusa::Fedora.client
      response = http.get(url + '/fcr:metadata', nil,
                          { 'Accept' => 'application/n-triples' })
      graph = RDF::Graph.new
      graph.from_ntriples(response.body)
      graph
    end

  end

end
