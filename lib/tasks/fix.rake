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

  desc 'correct peek type for unsupported image mime types'
  task :correct_image_peek => :environment do

    supported_image_subtypes = ['jp2', 'jpeg', 'dicom', 'gif', 'png', 'bmp']

    image_datafiles = Datafile.where(peek_type: PeekType::IMAGE)

    image_datafiles.each do |datafile|
      if datafile.mime_type && datafile.mime_type.length > 0 && datafile.mime_type.include?('/')
        mime_parts = datafile.mime_type.split("/")
        subtype = mime_parts[1].downcase

        unless supported_image_subtypes.include? (subtype)
          datafile.peek_type = PeekType::NONE
          datafile.save
        end
      else
        peek_type = PeekType::NONE
        datafile.save
      end
    end

  end


  desc 'find invalid datafiles'
  task :find_invalid_datafiles => :environment do
    Datafile.all.each do |datafile|
      if !datafile.storage_root
        puts "missing storage_root for datafile #{datafile.web_id}"
      elsif !datafile.storage_key
        puts "missing storage_key for datafile #{datafile.web_id}"
      elsif !datafile.current_root.exist?(datafile.storage_key)
        puts "missing binary for datafile #{datafile.web_id}, root: #{datafile.storage_root}, key: #{datafile.storage_key}"
      end
    end
  end

  desc 'migrate demo datasets'
  task :migrate_demo_datasets => :environment do

    host = IDB_CONFIG[:test_datacite_endpoint]
    user = IDB_CONFIG[:test_datacite_username]
    password = IDB_CONFIG[:test_datacite_password]
    shoulder = IDB_CONFIG[:test_datacite_shoulder]

    Dataset.all.each do |dataset|
      if dataset.identifier && dataset.identifier.include?('10.5072/FK2')
        dataset.identifier = "#{shoulder}#{dataset.key}_V1"


        target = "#{IDB_CONFIG[:root_url_text]}/datasets/#{dataset.key}"

        uri = URI.parse("https://#{host}/doi")

        request = Net::HTTP::Post.new(uri.request_uri)
        request.basic_auth(user, password)
        request.content_type = "text/plain;charset=UTF-8"
        request.body = "doi=#{dataset.identifier}\nurl=#{target}"

        sock = Net::HTTP.new(uri.host, uri.port)
        # sock.set_debug_output $stderr
        sock.use_ssl = true

        begin

          response = sock.start { |http| http.request(request) }

        rescue Net::HTTPBadResponse, Net::HTTPServerError => error
          puts "\nerror:" + error.message
          puts "\nresponse body: " + response.body

        end

        case response
        when Net::HTTPSuccess, Net::HTTPCreated, Net::HTTPRedirection
          dataset.save
        else
          puts "\nnot successful:"
          puts "\nrequest: " + request.to_yaml
          puts "\nresponse: " + response.to_yaml
        end

      end
    end
  end

end
