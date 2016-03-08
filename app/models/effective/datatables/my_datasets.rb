module Effective
  module Datatables
    class MyDatasets < Effective::Datatable

      datatable do
        current_email = attributes[:current_email]
        array_column "search", sortable: false, filter: {fuzzy: true} do |dataset|
          link_to(dataset.plain_text_citation, dataset_path(dataset.key))
        end

        array_column 'Visibility', filter: {type: :select, values: ['Private (Saved Draft)', 'Public (Published)', 'Public description, Private files', 'Private (Delayed Publication)', 'Public Metadata, Private Files (Tombstoned)', 'Private (Curator Hold)']} do |dataset|

          if dataset.curator_hold?
            render text: "Private (Curator Hold)"
          else
            case dataset.publication_state
              when Databank::PublicationState::DRAFT
                render text: "Private (Saved Draft)"
              when Databank::PublicationState::RELEASED
                render text: "Public (Published)"
              when Databank::PublicationState::FILE_EMBARGO
                render text: "Public description, Private files"
              when Databank::PublicationState::METADATA_EMBARGO
                render text: "Private (Delayed Publication)"
              when Databank::PublicationState::TOMBSTONE
                render text: "Public Metadata, Private Files (Tombstoned)"
              else
                #should never get here
                render text: "Unknown, please contact the Research Data Service"
            end
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
