module Effective
  module Datatables
    class DatasetChanges < Effective::Datatable
      datatable do

        # array_column :element  do |change|
        #   render text: change.audited_changes.keys.first
        # end
        # array_column :old_value do |change|
        #   render text: (change.audited_changes)[change.audited_changes.keys.first][0]
        # end
        # array_column :new_value do |change|
        #   render text: (change.audited_changes)[change.audited_changes.keys.first][1]
        # end
        # array_column :changed_by do |change|
        #   agent = User.find(change.user_id)
        #   render text: agent.name
        # end

        array_column :changes do |change|
          render text: "#{change.action}: #{change.audited_changes}"
        end

        # table_column :action

        # table_column :audited_changes

        table_column :created_at, label: "Timestamp", proc: Proc.new{|change| (change.created_at).iso8601}
        default_order :created_at, :desc

      end

      def collection
        changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', attributes[:dataset_id], attributes[:dataset_id])

        medusaChangesArr = Array.new
        publication = nil

        changes.each do |change|
          
          if (change.audited_changes.has_key?('medusa_path')) || (change.audited_changes.has_key?('binary_name')) || (change.audited_changes.has_key?('medusa_dataset_dir'))
            medusaChangesArr << change.id
          end
          if (change.audited_changes.keys.include?("publication_state"))

            pub_change = (change.audited_changes)["publication_state"]

            if pub_change.class == Array && pub_change[0] == Databank::PublicationState::DRAFT
              publication = change.created_at
            end

          end
        end

        if publication
          changes = changes.where("created_at >= ?", publication).where.not(id: medusaChangesArr)
        else
          Rails.logger.warn "no changes found for dataset #{attributes[:dataset_id]}"
          changes = Audited::Adapters::ActiveRecord::Audit.none
        end
        changes
      end

    end
  end
end