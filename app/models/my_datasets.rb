module Effective
  module Datatables
    class MyDatasets < Effective::Datatable

      datatable do
        current_email = attributes[:current_email]
        array_column "search", sortable: false, filter: {fuzzy: true} do |dataset|
          link_to(dataset.plain_text_citation, dataset_path(dataset.key))
        end

        array_column 'Visibility', filter: {type: :select, values: ['Private (Saved Draft)', 'Public (Published)', 'Public description, Private files (Standard Embargo)', 'Private (DOI Reserved Only)', 'Public Metadata, Private Files (Tombstoned)']} do |dataset|
          case dataset.publication_state
            when Databank::PublicationState::DRAFT
              render text: "Private (Saved Draft)"
            when Databank::PublicationState::RELEASED
              render text: "Public (Published)"
            when Databank::PublicationState::FILE_EMBARGO
              render text: "Public description, Private files (Standard Embargo)"
            when Databank::PublicationState::METADATA_EMBARGO
              render text: "Private (DOI Reserved Only)"
            when Databank::PublicationState::TOMBSTONE
              render text: "Public Metadata, Private Files (Tombstoned)"
            when Databank::PublicationState::DESTROYED
              render text: "Removed Metadata, Removed Files (Destroyed)"
            else
              #should never get here
              render text: "Unknown, please contact the Research Data Service"
          end

        end
      end


      def collection
        current_email = attributes[:current_email]
        Dataset.where(:depositor_email => current_email)
      end

    end
  end
end
