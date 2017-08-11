module Effective
  module Datatables
    class MyDatasets < Effective::Datatable

      datatable do
        current_email = attributes[:current_email]
        array_column :search, sortable: false, filter: {fuzzy: true} do |dataset|
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
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>#{h(table_description)}<br/>Keywords: #{table_keywords} ]
          elsif table_description
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>#{h(table_description)}]
          elsif table_keywords
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>Keywords: #{table_keywords} ]
          else
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %>]
          end
        end

        array_column 'Status', sortable: false, filter: {type: :select, values: ['Draft', 'Metadata and Files Publication Delayed (Embargoed)', 'Metadata Published, Files Publication Delayed (Embargoed)', 'Metadata and Files Published', 'Metadata Published, Files Temporarily Suppressed', 'Metadata and Files Temporarily Suppressed', 'Metadata Published, Files Withdrawn']} do |dataset|
          render text: "#{dataset.visibility}"
        end

        table_column :updated_at, visible: false
        default_order :updated_at, :desc

      end


      def collection
        current_email = attributes[:current_email]
        Dataset.where(:depositor_email => current_email).where.not(publication_state: Databank::PublicationState::PermSuppress::METADATA)
      end

    end
  end
end
