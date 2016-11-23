require 'rake'

namespace :datcite do

  task :diff_idb_datacite => :environment do

    datacite_status_array = Array.new


    Dataset.all.each do |dataset|

      status_hash = nil
      status_hash = Hash.new
      datacite_record_exists = nil

      status_hash.key = dataset.key
      status_hash.publication_state = dataset.publication_state

      existing_datacite_record = Dataset.datacite_record_hash(dataset)

      status_hash.datacite_record_exists = nil

      if existing_datacite_record
        datacite_record_exists = true
        status_hash.datacite_record_exists = "yes"
      else
        datacite_record_exists = false
        status_hash.datacite_record_exists = "no"
      end

      case dataset.publication_state

        when Databank::PublicationState::DRAFT
          if existing_datacite_record
            # something went wrong
          end

        when Databank::PublicationState::RELEASED
          if existing_datacite_record
            # check to see if the information is the same
          else
            # something went wrong
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
            # something went wrong
          end

        when Databank::PublicationState::TempSuppress::METADATA
          if existing_datacite_record
            # check to see if metadata is the same
          else
            # something went wrong
          end

        when Databank::PublicationState::TempSuppress::FILE
          # make sure metadata same

        when Databank::PublicationState::PermSuppress::METADATA
          if existing_datacite_record
            # check to see if metadata is placeholder alone
          else
            # ok
          end

        when Databank::PublicationState::PermSuppress::FILE
          if existing_datacite_record
            # check to see if metadata is correct
          else
            # ok
          end

      end

    end

  end

end