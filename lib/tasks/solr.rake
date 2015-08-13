namespace :solr do

  desc 'Clear the Solr index'
  task :clear => :environment do
    Solr::Solr.new.clear
  end

  desc 'Reindex the repository in Solr'
  task :reindex => :environment do
    Repository::Fedora.new.reindex
  end

  desc 'Update Solr schema'
  task :update_schema => :environment do
    Solr::Solr.new.update_schema
  end

end
