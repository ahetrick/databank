module Effective
  module Datatables
    class CuratorDatasets < Effective::Datatable
      datatable do
        table_column :depositor_name, label: 'search by depositor'
        array_column :search_citation, filter: {fuzzy: true} do |dataset|

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
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{dataset_path(dataset.key)}") %><br/>#{table_description}<br/><span class="metadata-label">Keyword(s): </span>#{table_keywords} ]
          elsif table_description
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{dataset_path(dataset.key)}") %><br/>#{table_description}]
          elsif table_keywords
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{dataset_path(dataset.key)}") %><br/><span class="metadata-label">Keyword(s): </span>#{table_keywords}]
          else
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{dataset_path(dataset.key)}") %>]
          end
        end

        array_column 'Visibility', filter: {type: :select, values: ['Private (Saved Draft)', 'Public (Published)', 'Public description, Private files (Standard Embargo)', 'Private (DOI Reserved Only)', 'Public Metadata, Private Files (Tombstoned)', 'Removed Metadata, Removed Files (Destroyed)']} do |dataset|
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
        table_column :updated_at, label: 'search by update date'
        default_order :updated_at, :desc
      end

      def collection
        Dataset.all
      end

    end
  end
end