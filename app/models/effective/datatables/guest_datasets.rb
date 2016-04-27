module Effective
  module Datatables
    class GuestDatasets < Effective::Datatable
      datatable do
        array_column  :search, type: :string, filter: {fuzzy: true} do |dataset|
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

      end


      def collection
        Dataset.where(publication_state: [Databank::PublicationState::RELEASED, Databank::PublicationState::Embargo::FILE]).where(is_test: false)
      end

    end
  end
end
