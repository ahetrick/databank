require 'rake'
namespace :s3update do

  desc 'update database values for medusa_storage'
  task :update4medusa_storage => :environment do
    Dataset.all.each do |dataset|
      #puts(dataset.key)

      dataset.datafiles.each do |datafile|

        if datafile.medusa_path && datafile.medusa_path != ''

          if Application.storage_manager.medusa_root.exist?(datafile.medusa_path)
            datafile.storage_root = 'medusa'
            datafile.storage_key = 'medusa_path'
            datafile.save
          else
            puts("could not find bytestream for medusa datafile #{datafile.web_id} in dataset #{dataset.key}")
          end

        elsif datafile.binary_name && datafile.binary_name != ""

          filename = datafile.binary_name.split("/")[-1]

          draft_key = "#{datafile.web_id}/#{datafile.filename}"

          unless datafile.storage_root && datafile.storage_root != '' && datafile.storage_key && datafile.storage_key != ''
            if Application.storage_manager.draft_root.exist?(draft_key)
              datafile.storage_root = 'draft'
              datafile.storage_key = draft_key
              datafile.save
            else
              puts("could not find draft bytestream for #{draft_key} in dataset: #{dataset.key}")
            end
          end

        end

      end


    end
  end

end