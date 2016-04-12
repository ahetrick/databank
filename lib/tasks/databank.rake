require 'rake'

namespace :databank do

  desc 'delete all datasets'
  task :delete_all => :environment do
    Dataset.all.each do |dataset|
      dataset.destroy
    end
  end

  desc 'delete all datafiles'
  task :delete_files => :environment do
    Datafile.all.each do |datafile|
      datafile.destroy
    end
  end

  desc 'delete all creators'
  task :delete_creators => :environment do
    Creator.all.each do |creator|
      creator.destroy
    end
  end

  desc "Clear users"
  task clear_users: :environment do
    User.all.each do |user|
      user.destroy
    end
    Identity.all.each do |identity|
      identity.destroy
    end
  end

  desc "Clear Rails cache (sessions, views, etc.)"
  task clear: :environment do
    Rails.cache.clear
  end

  desc 'Create demo users'
  task :create_users => :environment do
    salt = BCrypt::Engine.generate_salt
    encrypted_password = BCrypt::Engine.hash_secret("demo", salt)

    num_accounts = 10

    (1..num_accounts).each do |i|
      identity =   Identity.find_or_create_by(email: "demo#{i}@example.edu" )
      identity.name = "Demo#{i} Depositor"
      identity.password_digest = encrypted_password
      identity.save!
    end

    # create rspec test user -- not just identity
    auth = OmniAuth.config.mock_auth[:identity]
    user = User.create_with_omniauth(auth)
    user.save!

  end

  desc 'Retroactively set publication_state'
  task :update_state => :environment do
    Dataset.where.not(identifier: "").each do |dataset|
      dataset.publication_state = Databank::PublicationState::RELEASED
      dataset.save!
    end
  end

  desc 'Retroactively set datacite change status'
  task :update_datacite_flag => :environment do
    Dataset.all.each do |dataset|
      dataset.has_datacite_change = false
      dataset.save!
    end
  end

  desc 'fix name and size display for files ingested into Medusa'
  task :update_filename => :environment do
    MedusaIngest.all.each do |ingest|
      if ingest.medusa_path && ingest.medusa_path != ""
        datafile = Datafile.where(web_id: ingest.idb_identifier).first
        if datafile && File.exists?("#{IDB_CONFIG['medusa']['medusa_path_root']}/#{ingest.medusa_path}")
          datafile.binary_size = File.size("#{IDB_CONFIG['medusa']['medusa_path_root']}/#{ingest.medusa_path}")
          datafile.binary_name = File.basename("#{IDB_CONFIG['medusa']['medusa_path_root']}/#{ingest.medusa_path}")
          datafile.save!
        else
          puts "could not find datafile: #{ingest.idb_identifier} for ingest #{ingest.id}"
        end
      end
    end
  end

  desc 'clear empty datasets older than 12 hours'
  tasks :remove_empty_datasets => :environment do
    Dataset.where(publication_state: Databank::PublicationState::DRAFT).each do |draft|
      puts draft.to_yaml
    end

  end

end