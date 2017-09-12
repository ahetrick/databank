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

  desc 'fix specific record'
  task :fix_specific_record => :environment do

    record_to_fix = RelatedMaterial.find(78)
    if record_to_fix
      puts "Found Related Material 78"
      puts record_to_fix.to_yaml
      record_to_fix.uri = '10.13012/B2IDB-2031816_V2'
      record_to_fix.link = 'http://dx.doi.org/10.13012/B2IDB-2031816_V2'
      record_to_fix.save
    else
      puts "Did not find Related Mateiral 78"
    end

  end



end
