namespace :fix do

  desc 'fix missing version'
  task :fix_missing_version => :environment do
    datasets_missing_version = Dataset.where(dataset_version: nil)

    if datasets_missing_version.count > 0
      datasets_missing_version.each do |dataset|
        puts("Fixing missing version for dataset #{dataset.key}")
        dataset.dataset_version = '1'
        dataset.save
      end
    else
      puts("No datasets found with missing version.")
    end

  end

  desc 'pretend some dev datasets never happened'
  task :fix_dev => :environment do

    datasets_to_destroy = Dataset.where(key: ['IDBDEV-4257527', 'IDBDEV-5614232', 'IDBDEV-5614232'])

    datasets_to_destroy.each do |doomed|
      doomed.destroy!
    end

  end

  desc 'report top level mime types for datafiles on filesystem'
  task :datafile_mimes => :environment do
    Datafile.all.each do |datafile|
      begin
        file_info = `file --mime "#{datafile.filepath}"`
        puts file_info
      rescue StandardError => ex
        puts ex.message
      end


    end
  end

  desc 'remove orphan datafiles'
  task :remove_orphan_datafiles => :environment do

    Datafile.all.each do |datafile|
      datasets = Dataset.where(id: datafile.dataset_id)

      if datasets.count == 0

        datafile.destroy
        
      end

    end
  end

end
