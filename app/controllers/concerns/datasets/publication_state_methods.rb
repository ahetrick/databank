module Datasets

  module PublicationStateMethods
    extend ActiveSupport::Concern

    def send_deposit_confirmation_email (old_state, dataset)
      Rails.logger.warn "inside send_deposit_confirmation_email method for old_state #{old_state}, new_state: #{dataset.publication_state}, dataset: #{dataset.key}"
    end

    def deposit_confirmation_notice (old_state, dataset)

      new_state = dataset.publication_state

      case new_state
        when Databank::PublicationState::RELEASED
          return %Q[Dataset was successfully published and the DataCite DOI is #{dataset.identifier}.<br/>The persistent link to this dataset is now <a href = "http://dx.doi.org/#{dataset.identifier}">http://dx.doi.org/#{dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.]

        when Databank::PublicationState::METADATA_EMBARGO
          return %Q[DataCite DOI #{dataset.identifier} successfully reserved.<br/>The persistent link to this dataset will be <a href = "http://dx.doi.org/#{dataset.identifier}">http://dx.doi.org/#{dataset.identifier}</a> starting #{dataset.release_date}.]

        when Databank::PublicationState::FILE_EMBARGO
          return %Q[Dataset record was successfully published and the DataCite DOI is #{dataset.identifier}.<br/>Although the record for your dataset will be publicly visible, your data files will not be made available until #{dataset.release_date.iso8601}.<br/>The persistent link to this dataset is now <a href = "http://dx.doi.org/#{dataset.identifier}">http://dx.doi.org/#{dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.]
      end

    end


    def publish_modal_msg (dataset)

      # This method should only be called if there are DataCite relevant changes, including release date

      if !dataset.release_date || dataset.release_date <= Date.current()
        dataset.embargo = nil
      end

      msg = "<div class='confirm-modal-text'>"

      case dataset.embargo

        when Databank::PublicationState::FILE_EMBARGO
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "<h4>This action will make your record public and create a DOI.</h4><hr/>"
            msg << "<ul>"
            msg << "<li>Your Illinois Data Bank dataset record will be publicly visible through search engines.</li>"
            msg << "<li>Although the record for your dataset will be publicly visible, your data files will not be made available until #{dataset.release_date.iso8601}.</li>"

          else
            msg << "<h4>This action will make your updates to your dataset record public.</h4><hr/>"
            msg << "<ul>"
          end

        when Databank::PublicationState::METADATA_EMBARGO
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "<h4>This action will reserve a DOI</h4><hr/>"
            msg << "<ul>"
            msg << "<li>The DOI link will fail until #{dataset.release_date.iso8601}.</li>"
            msg << "<li>The record for your dataset is not visible, nor are your data files available until #{dataset.release_date.iso8601}.</li>"
          else
            # Should never get here, DataCite record changes are not relevant to METADATA_EMBARGO
            msg << "<h3>This action will not do anything.  The record for your dataset is not visible, and the DOI is already reserved.</h3>"
            msg << "<ul>"
          end

        else
          if dataset.publication_state == Databank::PublicationState::DRAFT
            msg << "<h4>This action will make your dataset public and create a DOI.</h4><hr/>"
          else
            msg << "<h4>This action will make your updates to your dataset record public.</h4>"
          end
          msg << "<ul>"
          msg << "<li>Your Illinois Data Bank dataset record will be publicly visible through search engines.</li>"
          msg << "<li>Your data files will be publicly available.</li>"
      end

      msg << "<li>You will be able to edit the description for the dataset to correct an error, but would need to contact the <a href='/help'>Research Data Service</a> if there is an error in the files that needs to be corrected.</li> "

      msg << "</ul></div>"

      msg
    end

    def create_doi(dataset)

      if dataset.is_import?
        raise "cannot create doi for imported dataset doi"
      end

      host = IDB_CONFIG[:ezid_host]
      uri = nil

      if dataset.is_test?
        shoulder = 'doi:10.5072/FK2'
        user = 'apitest'
        password = 'apitest'
      end

      shoulder = IDB_CONFIG[:ezid_shoulder]
      user = IDB_CONFIG[:ezid_username]
      password = IDB_CONFIG[:ezid_password]

      target = "#{request.base_url}#{dataset_path(dataset.key)}"

      metadata = {}
      metadata['_target'] = target
      if @dataset.publication_state == Databank::PublicationState::METADATA_EMBARGO
        metadata['_status'] = 'reserved'
      else
        metadata['_status'] = 'public'
        metadata['datacite'] = dataset.to_datacite_xml
        #Rails.logger.warn dataset.to_datacite_xml
      end

      if dataset.identifier && dataset.identifier != ''
        uri = URI.parse("https://#{host}/id/doi:#{dataset.identifier}")
      else
        uri = URI.parse("https://#{host}/id/#{shoulder}#{dataset.key}_v1")
      end

      request = Net::HTTP::Put.new(uri.request_uri)
      request.basic_auth(user, password)
      request.content_type = "text/plain"
      request.body = make_anvl(metadata)

      Rails.logger.warn "***** REQUEST START *****"
      Rails.logger.warn request.to_yaml
      Rails.logger.warn "***** REQUEST STOP *****"

      sock = Net::HTTP.new(uri.host, uri.port)
      sock.set_debug_output $stderr

      if uri.scheme == 'https'
        sock.use_ssl = true
      end

      begin

        response = sock.start { |http| http.request(request) }

      rescue Net::HTTPBadResponse, Net::HTTPServerError => error
        Rails.logger.warn error.message
        Rails.logger.warn response.body
      end

      case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          response_split = response.body.split(" ")
          Rails.logger.warn response_split
          response_split2 = response_split[1].split(":")
          Rails.logger.warn response_split2
          doi = response_split2[1]

        else
          Rails.logger.warn response.to_yaml
          raise "error creating DOI"
      end
    end


    def mint_doi(dataset)

      host = IDB_CONFIG[:ezid_host]

      if @dataset.is_test?
        shoulder = 'doi:10.5072/FK2'
        user = 'apitest'
        password = 'apitest'
      end

      shoulder = IDB_CONFIG[:ezid_shoulder]
      user = IDB_CONFIG[:ezid_username]
      password = IDB_CONFIG[:ezid_password]

      target = "#{request.base_url}#{dataset_path(dataset.key)}"

      metadata = {}
      metadata['_target'] = target
      if @dataset.publication_state == Databank::PublicationState::METADATA_EMBARGO
        metadata['_status'] = 'reserved'
      else
        metadata['_status'] = 'public'
        metadata['datacite'] = dataset.to_datacite_xml
      end

      uri = URI.parse("https://#{host}/shoulder/#{shoulder}")

      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(user, password)
      request.content_type = "text/plain"
      request.body = make_anvl(metadata)

      sock = Net::HTTP.new(uri.host, uri.port)
      # sock.set_debug_output $stderr

      if uri.scheme == 'https'
        sock.use_ssl = true
      end

      begin

        response = sock.start { |http| http.request(request) }

      rescue Net::HTTPBadResponse, Net::HTTPServerError => error
        Rails.logger.warn error.message
        Rails.logger.warn response.body
      end

      case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          response_split = response.body.split(" ")
          Rails.logger.warn response_split
          response_split2 = response_split[1].split(":")
          Rails.logger.warn response_split2
          doi = response_split2[1]

        else
          Rails.logger.warn response.to_yaml
          raise "error minting DOI"
      end
    end

  end

end

