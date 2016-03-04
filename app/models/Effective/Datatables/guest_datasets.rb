module Effective
  module Datatables
    class GuestDatasets < Effective::Datatable
      datatable do
        array_column :search, filter: {fuzzy: true} do |dataset|
          link_to(dataset.plain_text_citation, dataset_path(dataset.key))
        end
        table_column :updated_at, visible: false
        default_order :updated_at, :desc
      end


      def collection
        Dataset.where(publication_state: [Databank::PublicationState::RELEASED, Databank::PublicationState::FILE_EMBARGO])
      end

    end
  end
end