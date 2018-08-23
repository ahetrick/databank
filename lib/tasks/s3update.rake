require 'rake'
namespace :s3update do

  desc 'update database values for medusa_storage'
  task :update4medusa_storage => :environment do
    Dataset.all do |dataset|
      puts dataset.key

      dataset.datafiles do |datafile|

        if datafile.medusa_path && datafile.medusa_path != ''
          puts "datafile: #{datafile.key}, medusa_path: #{datafile.medusa_path}"

          if Application.storage_manager.medusa_root.exists?(datafile.medusa_path)
            puts("happy path")
          else
            puts("sad path")
          end

        end

      end


    end
  end

end