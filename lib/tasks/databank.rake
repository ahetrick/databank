require 'rake'
require 'open-uri'

namespace :databank do

  desc 'recover missing dois from file download tally records'
  task :recover_file_download => :environment do
    incomplete_records = FileDownloadTally.where(doi: "")
    incomplete_records.each do |tally|
      dataset = Dataset.find_by_key(tally.dataset_key)
      if dataset

        if dataset.identifier && dataset.identifier != ""

          tally.doi = dataset.identifier
          tally.save
        else
          tally.destroy
        end
      else
        puts tally.to_yaml
      end
    end
  end

  desc 'delete all datasets'
  task :delete_all => :environment do

    if IDB_CONFIG[:local_mode] == true
      Dataset.all.each do |dataset|
        dataset.destroy
      end
    else
      puts "Not local!"
    end

    Audited::Adapters::ActiveRecord::Audit.all.each do |audit|
      audit.destroy
    end



  end

  desc 'delete all datafiles'
  task :delete_files => :environment do

    if IDB_CONFIG[:local_mode] == true
      Datafile.all.each do |datafile|
        datafile.destroy
      end
    else
      puts "Not local!"
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
      identity = Identity.find_or_create_by(email: "demo#{i}@example.edu")
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

  desc 'remove empty datasets more than 12 hours old'
  task :remove_datasets_empty_12h => :environment do
    drafts = Dataset.where(publication_state: Databank::PublicationState::DRAFT)
    drafts.each do |draft|
      unless ((draft.title && draft.title != '')||(draft.creators.count > 0)||(draft.datafiles.count > 0)||(draft.funders.count > 0) || (draft.related_materials.count > 0) || (draft.description && draft.description != '') || (draft.keywords && draft.keywords != '') )
        if draft.created_at < (12.hours.ago)
          draft.destroy
        end
      end
    end
  end

  desc 'get latest list of robot ip addresses'
  task :get_robot_addresses => :environment do

    Robot.destroy_all

    source_base = "http://www.iplists.com/"
    sources = Array.new
    sources.push("google")
    sources.push("inktomi")
    sources.push("lycos")
    sources.push("infoseek")
    sources.push("altavista")
    sources.push("excite")
    sources.push("northernlight")
    sources.push("misc")
    sources.push("non_engines")

    sources.each do |source|
      robot_list_url = "#{source_base}#{source}.txt"
      # puts robot_list_url
      open(robot_list_url){|io|
        io.each_line {|line|
          if line[0] != "#" && line != "\n"
            Robot.create(source: source, address: line)
          end
        }
      }
    end

  end

  desc 'remove download records with ip addresses, if they are more than 3 days old'
  task :scrub_download_records => :environment do
    DayFileDownload.where("download_date < ?", 3.days.ago ).destroy_all
  end

  desc 'add legacy recordfiles'
  task :add_recordfiles => :environment do
    Dataset.all.each do |dataset|
      if dataset.identifier && dataset.identifier != '' && dataset.recordfile.nil?

        # create or confirm dataset_staging directory for dataset
        dataset_dirname = "DOI-#{(dataset.identifier).parameterize}"
        staging_dir = "#{IDB_CONFIG[:staging_root]}/#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}"
        file_time = Time.now.strftime('%Y-%m-%d_%H-%M')

        FileUtils.mkdir_p "#{staging_dir}/system"
        FileUtils.chmod "u=wrx,go=rx", File.dirname(staging_dir)

        # write recordfile

        recordfilename = "dataset_info_#{file_time}.txt"
        record_filepath = "#{staging_dir}/system/#{recordfilename}"

        File.open(record_filepath, "w") do |recordfile|
          recordfile.puts(dataset.recordtext)
        end

        recordfile = Recordfile.create(dataset_id: dataset.id)
        recordfile.binary = Pathname.new(record_filepath).open
        recordfile.save

        # make symlink, because setting as binary removes the file and puts it in uploads

        FileUtils.ln(recordfile.bytestream_path, record_filepath)
        FileUtils.chmod "u=wrx,go=rx", recordfile.bytestream_path

        medusa_ingest = MedusaIngest.new
        staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/#{recordfilename}"
        medusa_ingest.staging_path = staging_path
        medusa_ingest.idb_class = 'recordfile'
        medusa_ingest.idb_identifier = dataset.key
        medusa_ingest.send_medusa_ingest_message(staging_path)
        medusa_ingest.save
      end
    end
  end

  desc 'delete all recordfiles'
  task :delete_recordfiles => :environment do
    Dataset.all.each do |dataset|
      if dataset.recordfile
        dataset.recordfile.delete
      end
    end
  end

end