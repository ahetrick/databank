require 'open-uri'
require 'uri'
require 'net/http'
require 'openssl'

module Datacite
  extend ActiveSupport::Concern

  class_methods do

    def post_doi(dataset, current_user)

      raise("cannot create or update doi for incomplete dataset") unless Dataset.completion_check(dataset, current_user) == 'ok'

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

      system_user = User.find_by_provider_and_uid("system", IDB_CONFIG[:system_user_email])

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
        Rails.logger.warn "No Datacite record found when attempting to delete DataCite record for dataset #{dataset.key}."
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
        system_user = User.find_by_provider_and_uid("system", IDB_CONFIG[:system_user_email])
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

    def to_datacite_xml(dataset)

      if [Databank::PublicationState::PermSuppress::METADATA, Databank::PublicationState::TempSuppress::METADATA].include?(dataset.hold_state)
        return withdrawn_datacite_xml(dataset)
      elsif dataset.embargo == Databank::PublicationState::Embargo::METADATA
        return embargoed_datacite_xml(dataset)
      else
        return complete_datacite_xml(dataset)
      end

    end

    def embargoed_datacite_xml(dataset)

      raise "missing dataset identifier" unless (dataset.identifier && dataset.identifier != '')

      if !dataset.release_date
        raise "missing release date for file and metadata publication delay for dataset #{dataset.key}"
      elsif dataset.release_date.to_date < Date.current
        raise "invalid release date for file and metadata publication delay for dataset #{dataset.key}"
      end

      doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
      resourceNode = doc.first_element_child

      identifierNode = doc.create_element('identifier')
      identifierNode['identifierType'] = "DOI"
      identifierNode.content = dataset.identifier
      identifierNode.parent = resourceNode

      creatorsNode = doc.create_element('creators')
      creatorsNode.parent = resourceNode

      creatorNode = doc.create_element('creator')
      creatorNode.parent = creatorsNode

      creatorNameNode = doc.create_element('creatorName')

      creatorNameNode.content = "[Embargoed]"
      creatorNameNode.parent = creatorNode


      titlesNode = doc.create_element('titles')
      titlesNode.parent = resourceNode

      titleNode = doc.create_element('title')
      titleNode.content = "[This dataset will be available #{dataset.release_date.iso8601}. Contact us for more information. https://databank.illinois.edu/help#contact]"
      titleNode.parent = titlesNode

      publisherNode = doc.create_element('publisher')
      publisherNode.content = dataset.publisher || "University of Illinois at Urbana-Champaign"
      publisherNode.parent = resourceNode

      publicationYearNode = doc.create_element('publicationYear')
      publicationYearNode.content = dataset.publication_year || Time.now.year
      publicationYearNode.parent = resourceNode

      descriptionsNode = doc.create_element('descriptions')
      descriptionsNode.parent = resourceNode
      descriptionNode = doc.create_element('description')
      descriptionNode['descriptionType'] = "Other"
      descriptionNode.content = "This dataset will be available #{dataset.release_date.iso8601}. Contact us for more information. https://databank.illinois.edu/help#contact"
      descriptionNode.parent = descriptionsNode

      datesNode = doc.create_element('dates')
      datesNode.parent = resourceNode

      releasedateNode = doc.create_element('date')
      releasedateNode["dateType"] = "Available"
      releasedateNode.content = dataset.release_date.iso8601
      releasedateNode.content = dataset.release_date.iso8601
      releasedateNode.parent = datesNode

      doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
    end

    def withdrawn_datacite_xml(dataset)

      raise "missing dataset identifier" unless (dataset.identifier && dataset.identifier != '')

      doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
      resourceNode = doc.first_element_child

      identifierNode = doc.create_element('identifier')
      identifierNode['identifierType'] = "DOI"
      identifierNode.content = dataset.identifier
      identifierNode.parent = resourceNode

      creatorsNode = doc.create_element('creators')
      creatorsNode.parent = resourceNode

      creatorNode = doc.create_element('creator')
      creatorNode.parent = creatorsNode

      creatorNameNode = doc.create_element('creatorName')

      creatorNameNode.content = "[Redacted]"
      creatorNameNode.parent = creatorNode


      titlesNode = doc.create_element('titles')
      titlesNode.parent = resourceNode

      titleNode = doc.create_element('title')
      titleNode.content = "[Redacted]"
      titleNode.parent = titlesNode

      publisherNode = doc.create_element('publisher')
      publisherNode.content = dataset.publisher || "University of Illinois at Urbana-Champaign"
      publisherNode.parent = resourceNode

      publicationYearNode = doc.create_element('publicationYear')
      publicationYearNode.content = dataset.publication_year || Time.now.year
      publicationYearNode.parent = resourceNode

      descriptionsNode = doc.create_element('descriptions')
      descriptionsNode.parent = resourceNode
      descriptionNode = doc.create_element('description')
      descriptionNode['descriptionType'] = "Other"
      descriptionNode.content = "Removed by Illinois Data Bank curators. Contact us for more information. https://databank.illinois.edu/help#contact"
      descriptionNode.parent = descriptionsNode

      doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
    end

    def complete_datacite_xml(dataset)

      begin

        if dataset.keywords
          keywordArr = dataset.keywords.split(";")
        end

        contact = Creator.where(dataset_id: dataset.id, is_contact: true).first
        raise ActiveRecord::RecordNotFound unless contact

        doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
        resourceNode = doc.first_element_child

        identifierNode = doc.create_element('identifier')
        identifierNode['identifierType'] = "DOI"
        # for imports and post-v1 versions, use specified identifier, otherwise assert v1
        if dataset.identifier && dataset.identifier != ''
          identifierNode.content = dataset.identifier
        else
          identifierNode.content = "#{IDB_CONFIG[:ezid_placeholder_identifier]}#{dataset.key}_v1"
        end
        identifierNode.parent = resourceNode

        creatorsNode = doc.create_element('creators')
        creatorsNode.parent = resourceNode

        dataset.creators.each do |creator|
          creatorNode = doc.create_element('creator')
          creatorNode.parent = creatorsNode

          creatorNameNode = doc.create_element('creatorName')

          creatorNameNode.content = "#{creator.family_name.strip}, #{creator.given_name.strip}"
          creatorNameNode.parent = creatorNode

          # ORCID assumption hard-coded here, but in the model there is a field for identifier_scheme
          if creator.identifier && creator.identifier != ""
            creatorIdentifierNode = doc.create_element('nameIdentifier')
            creatorIdentifierNode['schemeURI'] = "http://orcid.org/"
            creatorIdentifierNode['nameIdentifierScheme'] = "ORCID"
            creatorIdentifierNode.content = "#{creator.identifier}"
            creatorIdentifierNode.parent = creatorNode
          end

        end

        titlesNode = doc.create_element('titles')
        titlesNode.parent = resourceNode

        titleNode = doc.create_element('title')
        titleNode.content = dataset.title || "Dataset Title"
        titleNode.parent = titlesNode

        contributorsNode = doc.create_element('contributors')
        contributorsNode.parent = resourceNode

        contactNode = doc.create_element('contributor')
        contactNode['contributorType'] = "ContactPerson"


        contactNameNode = doc.create_element('contributorName')

        if contact.family_name && contact.given_name
          contactNameNode.content = "#{contact.family_name.strip}, #{contact.given_name.strip}"
        elsif contact.institution_name
          contactNameNode.content = contact.institution_name.strip
        else
          raise "missing name for contact #{contact.to_yaml}"
        end

        contactNameNode.parent = contactNode

        if contact.identifier && contact.identifier != ""
          contactIdentifierNode = doc.create_element('nameIdentifier')
          contactIdentifierNode["schemeURI"] = "http://orcid.org/"
          contactIdentifierNode["nameIdentifierScheme"] = "ORCID"
          contactIdentifierNode.content = "#{contact.identifier}"
          contactIdentifierNode.parent = contactNode
        end

        contactNode.parent = contributorsNode

        if dataset.contributors.count > 0

          dataset.contributors.each do |contributor|

            contributorNode = doc.create_element('contributor')
            contributorNode['contributorType'] = "ContactPerson"

            contributorNameNode = doc.create_element('contributorName')

            contributorNameNode.content = "#{contributor.family_name.strip}, #{contributor.given_name.strip}"
            contributorNameNode.parent = contributorNode

            # ORCID assumption hard-coded here, but in the model there is a field for identifier_scheme
            if contributor.identifier && contributor.identifier != ""
              contributorIdentifierNode = doc.create_element('nameIdentifier')
              contributorIdentifierNode['schemeURI'] = "http://orcid.org/"
              contributorIdentifierNode['nameIdentifierScheme'] = "ORCID"
              contributorIdentifierNode.content = "#{contributor.identifier}"
              contributorIdentifierNode.parent = contributorNode
            end

            contributorNode.parent = contributorsNode
          end
        end

        dataset.funders.each do |funder|
          if (funder.name && funder.name != '') || (funder.identifier && funder.identifer != '')

            funderNode = doc.create_element('contributor')
            funderNode['contributorType'] = "Funder"
            funderNode.parent = contributorsNode

            funderNameNode = doc.create_element('contributorName')
            funderNameNode.content = funder.name ||= '[Name not provided]'
            funderNameNode.parent = funderNode

            if funder.identifier && funder.identifier != ''
              funderIdentifierNode = doc.create_element('nameIdentifier')
              funderIdentifierNode["schemeURI"] = "https://doi.org/"
              funderIdentifierNode["nameIdentifierScheme"] = "DOI"
              funderIdentifierNode.content = "#{funder.identifier}"
              funderIdentifierNode.parent = funderNode
            end
          end
        end


        publisherNode = doc.create_element('publisher')
        publisherNode.content = dataset.publisher || "University of Illinois at Urbana-Champaign"
        publisherNode.parent = resourceNode

        publicationYearNode = doc.create_element('publicationYear')
        publicationYearNode.content = dataset.publication_year || Time.now.year
        publicationYearNode.parent = resourceNode

        if dataset.keywords

          subjectsNode = doc.create_element('subjects')
          subjectsNode.parent = resourceNode

          keywordArr.each do |keyword|
            subjectNode = doc.create_element('subject')
            subjectNode.content = keyword.strip
            subjectNode.parent = subjectsNode
          end

        end

        datesNode = doc.create_element('dates')
        datesNode.parent = resourceNode

        releasedateNode = doc.create_element('date')
        releasedateNode["dateType"] = "Available"
        if dataset.tombstone_date && dataset.tombstone_date != ""
          releasedateNode.content = "#{dataset.release_date.iso8601}/#{dataset.tombstone_date.iso8601} "
        else
          if dataset.release_date && dataset.release_date != ''
            releasedateNode.content = dataset.release_date.iso8601
          else
            releasedateNode.content = Date.current.iso8601
          end

        end
        releasedateNode.parent = datesNode

        # languageNode = doc.create_element('language')
        # languageNode.content = "en-us"
        # languageNode.parent = resourceNode

        versionNode = doc.create_element('version')
        versionNode.content = dataset.dataset_version || "1"
        versionNode.parent = resourceNode

        if dataset.license && !dataset.license.blank?
          rightsListNode = doc.create_element('rightsList')
          rightsNode = doc.create_element('rights')

          case dataset.license

          when "CC01"

            rightsNode["rightsURI"] = "https://creativecommons.org/publicdomain/zero/1.0/"
            rightsNode.content = "CC0 1.0 Universal Public Domain Dedication (CC0 1.0)"
            rightsNode.parent = rightsListNode
            rightsListNode.parent = resourceNode

          when "CCBY4"

            rightsNode["rightsURI"] = "http://creativecommons.org/licenses/by/4.0/"
            rightsNode.content = "Creative Commons Attribution 4.0 International (CC BY 4.0)"
            rightsNode.parent = rightsListNode
            rightsListNode.parent = resourceNode

          when "license.txt"

            rightsNode.content = "See license.txt in dataset"
            rightsNode.parent = rightsListNode
            rightsListNode.parent = resourceNode

          else
            Rails.logger.warn "Unexpected license value #{dataset.license} for dataset #{dataset.key}"
          end


        end

        if dataset.description && !dataset.description.blank?
          descriptionsNode = doc.create_element('descriptions')
          descriptionsNode.parent = resourceNode
          descriptionNode = doc.create_element('description')
          descriptionNode['descriptionType'] = "Abstract"
          descriptionNode.content = dataset.description
          descriptionNode.parent = descriptionsNode
        end

        resourceTypeNode = doc.create_element('resourceType')
        resourceTypeNode['resourceTypeGeneral'] = "Dataset"
        resourceTypeNode.content = "Dataset"
        resourceTypeNode.parent = resourceNode


        if dataset.related_materials.count > 0

          ready_count = 0

          relatedIdentifiersNode = doc.create_element('relatedIdentifiers')
          relatedIdentifiersNode.parent = resourceNode

          dataset.related_materials.each do |material|

            if material.uri && material.uri != ''

              datacite_arr = Array.new

              if material.datacite_list && material.datacite_list != ''
                datacite_arr = material.datacite_list.split(',')
              else
                datacite_arr << 'IsSupplementTo'
              end

              datacite_arr.each do |relationship|
                ready_count = ready_count + 1
                relatedMaterialNode = doc.create_element('relatedIdentifier')
                relatedMaterialNode['relatedIdentifierType'] = material.uri_type || 'URL'
                relatedMaterialNode['relationType'] = relationship
                relatedMaterialNode.content = material.uri
                relatedMaterialNode.parent = relatedIdentifiersNode
              end

            end
          end

          if ready_count == 0
            relatedIdentifiersNode.remove
          end

        end

        return doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)

      rescue StandardError => error

        default_doc = Nokogiri::XML::Document.parse(%Q[<?xml version="1.0 encoding="UTF-8"?><error>Dataset Incomplete.</error>])
        return default_doc.to_xml

      end

    end

  end

end