require 'rake'
namespace :s3update do

  desc 'update database values for medusa_storage'
  task :update4medusa_storage => :environment do
    Dataset.all.each do |dataset|
      #puts(dataset.key)

      dataset.datafiles.each do |datafile|

        if !datafile.binary_name || datafile.binary_name == ''
          if datafile.storage_key
            datafile.binary_name = datafile.storage_key.split("/")[-1]
            datafile.save
          else
            puts("No binary_name for dataset: #{dataset.key} in datafile: #{datafile.web_id}")
          end
        end


        if datafile.medusa_path && datafile.medusa_path != ''

          datafile.binary_name = datafile.medusa_path.split("/")[-1]
          datafile.save

          if Application.storage_manager.medusa_root.exist?(datafile.medusa_path)
            datafile.storage_root = 'medusa'
            datafile.storage_key = datafile.medusa_path
            datafile.save
          else
            puts("could not find bytestream for medusa datafile #{datafile.web_id} in dataset #{dataset.key}")
          end

        elsif datafile.binary_name && datafile.binary_name != ""

          draft_key = "#{datafile.web_id}/#{datafile.binary_name}"

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