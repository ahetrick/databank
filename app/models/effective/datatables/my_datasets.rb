module Effective
  module Datatables
    class MyDatasets < Effective::Datatable

      datatable do
        current_email = attributes[:current_email]
        array_column :search, filter: {fuzzy: true} do |dataset|
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

        array_column 'Visibility', filter: {type: :select, values: ['Private (Saved Draft)','Private (Delayed Publication)','Public description, Private files (Delayed Publication)','Public (Published)','Public description, Private files (Curator Hold)','Private (Curator Hold)','Public Metadata, Redacted Files']} do |dataset|
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
