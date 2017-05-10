module Datacite
  extend ActiveSupport::Concern

  class_methods do

    def create_doi(dataset, current_user)

      if dataset.is_import?
        raise "cannot create doi for imported dataset doi"
      end

      host = IDB_CONFIG[:ezid_host]
      uri = nil

      if dataset.is_test?
        shoulder = '10.5072/FK2'
        user = 'apitest'
        password = 'apitest'
      else
        shoulder = IDB_CONFIG[:ezid_shoulder]
        user = IDB_CONFIG[:ezid_username]
        password = IDB_CONFIG[:ezid_password]
      end

      # use specified DOI if provided
      # this temporary identifier also helps to handle previous failed or partial publication

      if !dataset.identifier || dataset.identifier == ''
        dataset.identifier = "#{shoulder}#{dataset.key}_V1"
      end

      existing_datacite_record = Dataset.datacite_record_hash(dataset)

      if existing_datacite_record
        # we might get here if there was a previous partial publish
        Dataset.update_datacite_metadata(dataset, current_user)
        return dataset.identifier
      end

      target = "#{IDB_CONFIG[:root_url_text]}/datasets/#{dataset.key}"

      metadata = {}
      metadata['_target'] = target
      if dataset.publication_state == Databank::PublicationState::Embargo::METADATA
        metadata['_status'] = 'reserved'
      else
        metadata['_status'] = 'public'
        metadata['datacite'] = dataset.to_datacite_xml
      end

      uri = URI.parse("https://#{host}/id/doi:#{dataset.identifier}")

      request = Net::HTTP::Put.new(uri.request_uri)
      request.basic_auth(user, password)
      request.content_type = "text/plain;charset=UTF-8"
      request.body = Dataset.make_anvl(metadata)

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
          response_split2 = response_split[1].split(":")
          doi = response_split2[1]
          return doi

        else
          Rails.logger.warn response.to_yaml
          raise "error creating DOI"
      end
    end

    def update_datacite_metadata(dataset, current_user)

      if Dataset.completion_check(dataset, current_user) == 'ok'

        existing_datacite_record = datacite_record_hash(dataset)

        if !existing_datacite_record
          if dataset.identifier.include? "10.5072/FK2"
            create_doi(dataset, current_user)
            return true
          else
            Rails.logger.warn "No Datacite record found when attempting to update DataCite record for dataset #{dataset.key}."
            return nil
          end
        end

        user = nil
        password = nil
        host = IDB_CONFIG[:ezid_host]

        if dataset.is_test?
          user = 'apitest'
          password = 'apitest'
        else
          user = IDB_CONFIG[:ezid_username]
          password = IDB_CONFIG[:ezid_password]
        end

        target = "#{IDB_CONFIG[:root_url_text]}/datasets/#{dataset.key}"

        metadata = {}

        # For reserved DOIs remaining in Metadata & File embargo, do not send status or metadata
        if dataset.publication_state == Databank::PublicationState::Embargo::METADATA && dataset.embargo == Databank::PublicationState::Embargo::METADATA
          return true
        end

        if ((dataset.publication_state == Databank::PublicationState::PermSuppress::METADATA) || (dataset.hold_state == Databank::PublicationState::TempSuppress::METADATA))
          metadata['_status'] = "unavailable | Removed by Illinois Data Bank curators. Contact us for more information. #{ IDB_CONFIG[:root_url_text] }/help#contact"
        elsif existing_datacite_record[:status]!= 'reserved' && dataset.publication_state == Databank::PublicationState::Embargo::METADATA
          metadata['_status'] = "unavailable | Embargoed. This dataset will be available #{dataset.release_date.iso8601}."
        elsif [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::RELEASED].include?(dataset.publication_state)
          metadata['_status'] = 'public'
        end
        # For File-only Temporary or Permenant Suppression, make no change to _status

        metadata['_target'] = target

        if ((dataset.publication_state == Databank::PublicationState::PermSuppress::METADATA) || (dataset.hold_state == Databank::PublicationState::TempSuppress::METADATA))
          metadata['datacite'] = dataset.withdrawn_metadata
        elsif existing_datacite_record[:status]!= 'reserved' && dataset.publication_state == Databank::PublicationState::Embargo::METADATA
          metadata['datacite'] = dataset.embargo_metadata
        else
          metadata['datacite'] = metadata['datacite'] = dataset.to_datacite_xml
        end

        uri = URI.parse("https://#{host}/id/doi:#{dataset.identifier}")

        request = Net::HTTP::Post.new(uri.request_uri)
        request.basic_auth(user, password)
        request.content_type = "text/plain;charset=UTF-8"
        request.body = Dataset.make_anvl(metadata)

        sock = Net::HTTP.new(uri.host, uri.port)

        if uri.scheme == 'https'
          sock.use_ssl = true
        end

        begin

          response = sock.start { |http| http.request(request) }
          case response
            when Net::HTTPSuccess, Net::HTTPRedirection
              return true

            else
              Rails.logger.warn response.to_yaml
              return false
          end

        rescue Net::HTTPBadResponse, Net::HTTPServerError => error
          Rails.logger.warn "bad response when trying to update DataCite metadata for dataset #{dataset.key}"
          Rails.logger.warn error.message
          Rails.logger.warn response.body
        end


      else
        Rails.logger.warn "dataset not detected as complete - #{Dataset.completion_check(dataset, current_user)}"
        return false
      end

    end


    def datacite_record_hash(dataset)

      response = ezid_metadata_response(dataset)

      return nil unless response

      #Rails.logger.warn response.to_yaml

      response_hash = Hash.new
      response_body_hash = Hash.new
      response_lines = response.body.to_s.split("\n")
      response_lines.each do |line|
        split_line = line.split(": ")
        response_body_hash["#{split_line[0]}"] = "#{split_line[1]}"
      end

      return nil unless response_body_hash["_created"]

      response_hash["target"] = response_body_hash["_target"]
      response_hash["created"]= (Time.at(Integer(response_body_hash["_created"])).to_datetime).strftime("%Y-%m-%d at %I:%M%p")
      response_hash["updated"]= (Time.at(Integer(response_body_hash["_updated"])).to_datetime).strftime("%Y-%m-%d at %I:%M%p")
      response_hash["owner"] = response_body_hash["_owner"]
      response_hash["status"] = response_body_hash["_status"]
      response_hash["datacenter"] = response_body_hash["_datacenter"]

      #reserved DOIs won't have datacite element
      if response_body_hash["datacite"]

        clean_metadata_xml_string = (response_body_hash["datacite"]).gsub("%0A", '')
        metadata_doc = Nokogiri::XML(clean_metadata_xml_string)
        response_hash["metadata"] = metadata_doc

      end

      return response_hash

    end

    def ezid_metadata_response(dataset)

      host = IDB_CONFIG[:ezid_host]

      begin

        uri = URI.parse("htggtps://#{host}/id/doi:#{dataset.identifier}")
        response = Net::HTTP.get_response(uri)

        case response
          when Net::HTTPSuccess, Net::HTTPRedirection
            return response

          else
            # Rails.logger.warn response.to_yaml
            # logging a warning every time is excessive since we don't always expect a record to exist
            return nil
        end

      rescue StandardError => error
        Rails.logger.warn "error attempting to get ezid response for dataset #{dataset.key}"
        raise error
      end


    end

    def delete_datacite_id(dataset, current_user)

      existing_datacite_record = datacite_record_hash(dataset)

      if !existing_datacite_record
        Rails.logger.warn "No Datacite record found when attempting to delete DataCite record for dataset #{dataset.key}."
        return true
      end

      if existing_datacite_record[:status] == 'reserved'

        user = nil
        password = nil
        host = IDB_CONFIG[:ezid_host]

        if dataset.is_test?
          user = 'apitest'
          password = 'apitest'
        else
          user = IDB_CONFIG[:ezid_username]
          password = IDB_CONFIG[:ezid_password]
        end

        uri = URI.parse("https://#{host}/id/doi:#{dataset.identifier}")

        request = Net::HTTP::Delete.new(uri.request_uri)
        request.basic_auth(user, password)
        request.content_type = "text/plain"

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
          Dataset.update_datacite_metadata(dataset, current_user)
          return true
        end

        case response
          when Net::HTTPSuccess, Net::HTTPRedirection
            return true

          else
            Rails.logger.warn response.to_yaml
            return false
        end

      else
        # if we get here, we are suppressing a dataset with a Metadata & File embargoed dataset that been released,
        # and so could not have a _status of 'reserved
        Dataset.update_datacite_metadata(dataset, current_user)
        return true
      end

    end

  end

end