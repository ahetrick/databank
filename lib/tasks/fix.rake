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

    datasets_to_destroy = Dataset.where(key: ['IDBDEV-2325482', 'IDBDEV-8137448', 'IDBDEV-2537025', 'IDBDEV-3550218', 'IDBDEV-9796286', 'IDBDEV-6745942', 'IDBDEV-4070155', 'IDBDEV-2272192', 'IDBDEV-9273922', 'IDBDEV-4994376', 'IDBDEV-7714370', 'IDBDEV-0335695', 'IDBDEV-9569302', 'IDBDEV-8621302', 'IDBDEV-5890929', 'IDBDEV-2295011', 'IDBDEV-6588788', 'IDBDEV-9358392', 'IDBDEV-1212907', 'IDBDEV-4517640', 'IDBDEV-6003586', 'IDBDEV-4072738', 'IDBDEV-5830846', 'IDBDEV-3603811'])

    datasets_to_destroy.each do |doomed|
      doomed.destroy!
    end

  end

end
