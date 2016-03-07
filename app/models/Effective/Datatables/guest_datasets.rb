module Effective
  module Datatables
    class GuestDatasets < Effective::Datatable
      datatable do
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
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{dataset_path(dataset.key)}") %><br/>#{table_description}<br/><span class="metadata-label">Keyword(s): </span>#{table_keywords} ]
          elsif table_description
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{dataset_path(dataset.key)}") %><br/>#{table_description}]
          elsif table_keywords
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{dataset_path(dataset.key)}") %><br/><span class="metadata-label">Keyword(s): </span>#{table_keywords}]
          else
            render inline: %Q[<%= link_to("#{dataset.plain_text_citation}", "#{dataset_path(dataset.key)}") %>]
          end
        end
        # table_column :description
        # table_column :keywords
        table_column :updated_at, visible: false
        default_order :updated_at, :desc
      end


      def collection
        Dataset.where(publication_state: [Databank::PublicationState::RELEASED, Databank::PublicationState::FILE_EMBARGO])
      end

    end
  end
end