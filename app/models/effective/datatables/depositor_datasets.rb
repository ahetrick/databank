module Effective
  module Datatables
    class DepositorDatasets < Effective::Datatable

      datatable do
        current_email = attributes[:current_email]
        current_name = attributes[:current_name]
        array_column 'My Datasets + All', sortable: false, filter: {type: :select, values: ['mine']} do |dataset|
          if dataset.depositor_email == current_email
            render text: 'mine'
          else
            render text: ''
          end
        end

        # table_column :depositor_name, label: 'My Datasets / All', sortable: false, filter: {type: :select, values: [current_name, ''] }  do |dataset|
        #   render text: dataset.depositor_name
        # end
        array_column :citation, label: 'Search', sortable: false, filter: {fuzzy: true} do |dataset|
          table_description = nil
          if dataset.description && !dataset.description.empty?
            table_description = dataset.description.first(230)
            if dataset.description.length > 230
              table_description = table_description + "[...]"
            end
          end

          table_keywords = nil
          if dataset.keywords && dataset.keywords != ""
            table_keywords = dataset.keywords
          end

          if table_description && table_keywords
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>#{table_description}<br/>Keywords: #{table_keywords} ]
          elsif table_description
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>#{table_description}]
          elsif table_keywords
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>Keywords: #{table_keywords} ]
          else
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{request.base_url}#{dataset_path(dataset.key)}") %>]
          end
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
        table_column :updated_at, visible: false
        default_order :updated_at, :desc
      end

      def collection
        current_email = attributes[:current_email]
        Dataset.where.not(publication_state: Databank::PublicationState::DESTROYED).where(is_test: false).where("publication_state = ? OR publication_state = ? OR depositor_email = ?", Databank::PublicationState::FILE_EMBARGO, Databank::PublicationState::RELEASED, current_email)
      end

    end
  end
end
