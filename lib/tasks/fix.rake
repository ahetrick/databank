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

    datasets_to_destroy = Dataset.where(key: ['IDBDEV-6003586'])

    datasets_to_destroy.each do |doomed|
      doomed.destroy!
    end

  end

end
