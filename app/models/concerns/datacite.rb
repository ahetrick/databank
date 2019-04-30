require 'open-uri'
require 'uri'
require 'net/http'
require 'openssl'

module Datacite
  extend ActiveSupport::Concern

  class_methods do

    def post_doi(dataset, current_user)

      completion_status = Dataset.completion_check(dataset, current_user)
      raise("no doi for incomplete dataset: #{completion_status}") unless completion_status == 'ok'

      if dataset.is_test?
        host = IDB_CONFIG[:test_datacite_endpoint]
        user = IDB_CONFIG[:test_datacite_username]
        password = IDB_CONFIG[:test_datacite_password]
        shoulder = IDB_CONFIG[:test_datacite_shoulder]
      else
        host = IDB_CONFIG[:datacite_endpoint]
        user = IDB_CONFIG[:datacite_username]
        password = IDB_CONFIG[:datacite_password]
        shoulder = IDB_CONFIG[:datacite_shoulder]
      end

      # use specified DOI if provided

      if !dataset.identifier || dataset.identifier == ''
        dataset.identifier = "#{shoulder}#{dataset.key}_V1"
      end

      target = "#{IDB_CONFIG[:root_url_text]}/datasets/#{dataset.key}"

      uri = URI.parse("https://#{host}/doi")

      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(user, password)
      request.content_type = "text/plain;charset=UTF-8"
      request.body = "doi=#{dataset.identifier}\nurl=#{target}"

      sock = Net::HTTP.new(uri.host, uri.port)
      sock.set_debug_output $stderr
      sock.use_ssl = true

      begin

        response = sock.start { |http| http.request(request) }

      rescue Net::HTTPBadResponse, Net::HTTPServerError => error
        Rails.logger.warn "bad or error response to doi post attempt"
        Rails.logger.warn error.message
        Rails.logger.warn response.body
        return false
      end

      case response
      when Net::HTTPSuccess, Net::HTTPCreated, Net::HTTPRedirection
        dataset.save
        return true
      else
        Rails.logger.warn "non-success response to doi post attempt"
        Rails.logger.warn request.to_yaml
        Rails.logger.warn response.to_yaml
        return false
      end

    end

    def post_doi_metadata(dataset, current_user)

      system_user = User::Shibboleth.find_by_provider_and_uid("system", IDB_CONFIG[:system_user_email])

      raise("cannot create or update doi for incomplete dataset") unless current_user = system_user || Dataset.completion_check(dataset, current_user) == 'ok'

      #embargoed, supressed, and curator held metadata is handled by the to_datacite_xml method

      if dataset.is_test?
        host = IDB_CONFIG[:test_datacite_endpoint]
        user = IDB_CONFIG[:test_datacite_username]
        password = IDB_CONFIG[:test_datacite_password]
        shoulder = IDB_CONFIG[:test_datacite_shoulder]
      else
        host = IDB_CONFIG[:datacite_endpoint]
        user = IDB_CONFIG[:datacite_username]
        password = IDB_CONFIG[:datacite_password]
        shoulder = IDB_CONFIG[:datacite_shoulder]
      end

      # use specified DOI if provided

      if !dataset.identifier || dataset.identifier == ''
        dataset.identifier = "#{shoulder}#{dataset.key}_V1"
      end

      uri = URI.parse("https://#{host}/metadata")

      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(user, password)
      request.content_type = "application/xml;charset=UTF-8"
      request.body = Dataset.to_datacite_xml(dataset)

      sock = Net::HTTP.new(uri.host, uri.port)
      sock.set_debug_output $stderr
      sock.use_ssl = true

      begin

        response = sock.start { |http| http.request(request) }

      rescue Net::HTTPBadResponse, Net::HTTPServerError => error
        Rails.logger.warn "bad or error response to doi metadata post attempt"
        Rails.logger.warn error.message
        Rails.logger.warn request.to_yaml
        return false
      end

      case response
      when Net::HTTPSuccess, Net::HTTPCreated, Net::HTTPRedirection
        dataset.save
        return true
      else
        Rails.logger.warn "non-success response to doi metadata post attempt"
        Rails.logger.warn request.to_yaml
        Rails.logger.warn response.to_yaml
        return false
      end

    end

    def get_doi_metadata(dataset)

      return nil unless (dataset.identifier && dataset.identifier != '')

      host = IDB_CONFIG[:datacite_endpoint]
      user = IDB_CONFIG[:datacite_username]
      password = IDB_CONFIG[:datacite_password]

      begin

        uri = URI.parse("https://#{host}/metadata/#{dataset.identifier}")

        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(user, password)

        sock = Net::HTTP.new(uri.host, uri.port)

        if uri.scheme == 'https'
          sock.use_ssl = true
        end

        response = sock.start { |http| http.request(request) }

        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          return response.body
        else
          # Rails.logger.warn response.to_yaml
          # logging a warning every time is excessive since we don't always expect a record to exist
          return nil
        end

      rescue Net::HTTPBadResponse, Net::HTTPServerError => error
        Rails.logger.warn "error attempting to get metadata from DataCite Metadata Store for dataset #{dataset.key}"
        return nil
      end
    end

    def delete_doi_metadata(dataset)

      existing_datacite_record = get_doi_metadata(dataset)

      if !existing_datacite_record
        Rails.logger.warn "No DataCite record found when attempting to delete DataCite record for dataset #{dataset.key}."
        return true
      end

      if dataset.is_test?
        host = IDB_CONFIG[:test_datacite_endpoint]
        user = IDB_CONFIG[:test_datacite_username]
        password = IDB_CONFIG[:test_datacite_password]
      else
        host = IDB_CONFIG[:datacite_endpoint]
        user = IDB_CONFIG[:datacite_username]
        password = IDB_CONFIG[:datacite_password]
      end

      uri = URI.parse("https://#{host}/metadata/#{dataset.identifier}" )

      request = Net::HTTP::Delete.new(uri.request_uri)
      request.basic_auth(user, password)
      request.content_type = "text/plain"

      sock = Net::HTTP.new(uri.host, uri.port)
      sock.use_ssl = true

      begin

        response = sock.start { |http| http.request(request) }

      rescue Net::HTTPBadResponse, Net::HTTPServerError => error

        Rails.logger.warn "problem is before response"
        Rails.logger.warn error.message
        #Rails.logger.warn request.to_yaml
        return false
      end

      case response
      when Net::HTTPUnprocessableEntity
        # fix bad state of no metadata, from previous api state
        system_user = User::User.find_by_provider_and_uid("system", IDB_CONFIG[:system_user_email])
        Dataset.post_doi_metadata(dataset, system_user)

        uri = URI.parse("https://#{host}/metadata/#{dataset.identifier}" )

        request = Net::HTTP::Delete.new(uri.request_uri)
        request.basic_auth(user, password)
        request.content_type = "text/plain"

        sock = Net::HTTP.new(uri.host, uri.port)
        sock.use_ssl = true
        retry_response = sock.start { |http| http.request(request) }

        if retry_response == Net::HTTPSession || Net::HTTPRedirection
          return true
        else
          Rails.logger.warn("retry did not work for #{dataset.key}")
          return false
        end

      when Net::HTTPSuccess, Net::HTTPRedirection
        return true
      else
        Rails.logger.warn "problem is in response"
        #Rails.logger.warn request.to_yaml
        #Rails.logger.warn response.to_yaml
        return false
      end

    end

  end

end