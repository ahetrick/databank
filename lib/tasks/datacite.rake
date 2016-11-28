require 'rake'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'nokogiri/diff'

namespace :datacite do

  desc 'detect and report conflict between IDB and DataCite records'
  task :diff_datacite => :environment do

    datacite_report = "key, idb_url, has_ezid_record, has_conflict\n"

    Dataset.all.each do |dataset|

      existing_datacite_record = Dataset.datacite_record_hash(dataset)
      existing_idb_record = Net::HTTP.get(URI.parse("#{IDB_CONFIG[:root_url_text]}/datasets/#{dataset.key}.xml"))

      has_conflict = nil

      case dataset.publication_state

        when Databank::PublicationState::DRAFT
          if existing_datacite_record
            has_conflict = true
          else
            has_conflict = false
          end

        when Databank::PublicationState::RELEASED
          if existing_datacite_record

            ezid_doc = existing_datacite_record["metadata"]

            idb_doc = Nokogiri::XML(existing_idb_record)

            doc1 = ezid_doc
            doc2 = idb_doc

            has_conflict = false
            doc1.diff(doc2) do |change,node|
              if change.length > 1
                has_conflict = true
              end
            end

          else
            has_conflict = true
          end

        when Databank::PublicationState::Embargo::METADATA
          if existing_datacite_record
            # check to see if the metadata is placeholder only
          else
            # something went wrong
          end

        when Databank::PublicationState::Embargo::FILE
          if existing_datacite_record
            # check to see if metadata is correct
          else
            has_conflict = true
          end

        when Databank::PublicationState::TempSuppress::METADATA
          if existing_datacite_record
            # check to see if metadata is the same
          else
            has_conflict = true
          end

        when Databank::PublicationState::TempSuppress::FILE
          # make sure metadata same

        when Databank::PublicationState::PermSuppress::METADATA
          if existing_datacite_record
            # check to see if metadata is placeholder alone
          else
            has_conflict = true
          end

        when Databank::PublicationState::PermSuppress::FILE
          if existing_datacite_record
            # check to see if metadata is correct
          else
            has_conflict = true
          end

      end

      datacite_report << "#{dataset.key}, #{IDB_CONFIG[:root_url_text]}/datasets/#{dataset.key}, #{existing_datacite_record ? true : false}, #{has_conflict}\n"

    end

  end

end