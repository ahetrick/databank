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
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>#{table_description}<br/>Keywords: #{table_keywords} ]
          elsif table_description
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>#{table_description}]
          elsif table_keywords
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>Keywords: #{table_keywords} ]
          else
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %>]
          end
        end

        array_column 'Visibility', filter: {type: :select, values: ['Private (Saved Draft)', 'Public (Published)', 'Public description, Private files', 'Private (Delayed Publication)', 'Public Metadata, Private Files (Tombstoned)', 'Removed Metadata, Removed Files (Destroyed)', 'Private (Curator Hold)']} do |dataset|

          render text: "#{dataset.visibility}"
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
