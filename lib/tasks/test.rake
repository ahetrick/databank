require 'rake'
require 'bunny'
require 'json'

namespace :test do

  desc 'send a RabbitMQ message'
  task :send_msg => :environment do
    puts "sending message"

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q = ch.queue("idb_to_medusa", :durable => true)
    x = ch.default_exchange

    # q.subscribe do |delivery_info, metadata, payload|
    #   puts "Received #{payload}"
    # end

    x.publish("This might be a message.", :routing_key => q.name)

    conn.close

  end

  desc 'get a RabbitMQ message'
  task :get_msg => :environment do
    puts "getting message"

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q = ch.queue("medusa_to_idb", :durable => true)
    x = ch.default_exchange

    delivery_info, properties, payload = q.pop
    if payload.nil?
      puts "No message found."
    else
      puts "This is the message: " + payload + "\n\n"
    end

    conn.close

  end

  desc 'simulate RabbitMQ ok response from Medusa'
  task :send_ok => :environment do
    puts "sending message"

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q = ch.queue("medusa_to_idb", :durable => true)
    x = ch.default_exchange

    # q.subscribe do |delivery_info, metadata, payload|
    #   puts "Received #{payload}"
    # end

    msg_hash = {status: 'ok',
                operation: 'ingest',
                staging_path: 'uploads/5g06s/test.txt',
                medusa_path: '5g06s_test.txt',
                medusa_uuid: '149603bb-0cad-468b-9ef0-e91023a5d455',
                error: ''}

    x.publish("#{msg_hash.to_json}", :routing_key => q.name)

    conn.close

  end

  desc 'simulate RabbitMQ error response from Medusa'
  task :send_error => :environment do
    puts "sending message"

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q = ch.queue("medusa_to_idb", :durable => true)
    x = ch.default_exchange

    # q.subscribe do |delivery_info, metadata, payload|
    #   puts "Received #{payload}"
    # end

    msg_hash = {status: 'error',
                operation: 'ingest',
                staging_path: 'uploads/tbzaq/test.txt',
                medusa_path: '',
                medusa_uuid: '',
                error: 'malformed thingy'}

    x.publish("#{msg_hash.to_json}", :routing_key => q.name)

    conn.close

  end

  desc 'send duplicate file messages'
  task :send_medusa_dup => :environment do

    File.open("#{IDB_CONFIG[:datafile_store_dir]}/test/test.txt", "w") do |test_file|
      test_file.write("Initial placeholder content.")
    end
    puts "creating ingest message"
    medusa_ingest = MedusaIngest.new
    staging_path = "uploads/test/test.txt"
    medusa_ingest.staging_path = staging_path
    medusa_ingest.idb_class = 'test'
    medusa_ingest.idb_identifier = "test_#{Time.now.strftime('%Y-%m-%d_%H-%M')}"
    puts "sending message"
    medusa_ingest.send_medusa_ingest_message(staging_path)
    medusa_ingest.save
    puts "Ingest Message Record:"
    puts medusa_ingest.to_yaml

  end

  desc 'expose license info array'
  task :list_info => :environment do
    LICENSE_INFO_ARR.each do |info|
      puts info.to_yaml
    end
  end

  desc 'report storage mode status'
  task :report_storage_mode => :environment do

    Databank::Application.file_mode = 'error'

    mount_path = (Pathname.new(IDB_CONFIG[:storage_mount]).realpath).to_s.strip
    read_only_path = (IDB_CONFIG[:read_only_realpath]).to_s.strip
    read_write_path = (IDB_CONFIG[:read_write_realpath]).to_s.strip

    if (mount_path.casecmp(read_only_path) == 0)
      Databank::Application.file_mode = Databank::FileMode::READ_ONLY
    elsif(mount_path.casecmp(read_write_path) == 0)
      Databank::Application.file_mode = Databank::FileMode::WRITE_READ
    end

    puts "*******"
    puts "* STORAGE MODE REPORT for #{IDB_CONFIG[:root_url_text]} "
    puts "*******"
    write_succeeded = false

    # try to write
    begin
      file = File.open("#{mount_path}/testme.txt", "w")
      write_succeeded = true if file
    rescue Exception => ex
      puts ex.class
      puts ex.message
      write_succeeded = false
    ensure
      file.close unless (file.nil? || file.closed?)
      FileUtils.rm_f("#{mount_path}/testme.txt")
    end

    #try to read

    datafile = Datafile.find_by_web_id("#{IDB_CONFIG[:sample_datafile]}")

    unless datafile
      puts "datafile #{IDB_CONFIG[:sample_datafile]} not found"
      exit!
    end

    read_succeeded = false

    if File.file?(datafile.bytestream_path)
      read_string = IO.read(datafile.bytestream_path)
      read_succeeded = read_string && read_string.length > 0
    end

    # if read-only mode, expect write to fail
    # if read-write mode, expect write to succeed
    # expect read to succeed



    case Databank::Application.file_mode
      when Databank::FileMode::READ_ONLY
        puts "*  CURRENT MODE: read only"
        if write_succeeded
          puts "* WRITE ERROR: write succeeded, but it was not expected to"
        else
          puts "* WRITE OK: write did not succeed as expected"
        end
      when Databank::FileMode::WRITE_READ
        puts "* CURRENT MODE: read and write"
        if write_succeeded
          puts "* WRITE OK: write succeed as expected"
        else
          puts "* WRITE ERROR: write did not succeed, but it was expected to"
        end
      else
        puts "* Unexpected value for file storage mode flag: #{Databank::Application.file_mode}"
    end
    if read_succeeded
      puts "* READ OK: read succeed as expected"
    else
      puts "* READ ERROR: read did not succeed, but it was expected to"
    end
    puts "*"
    puts "* configuration details:"
    puts "*"
    puts "* configuration file is in /home/databank/shared/config/databank.yml"
    puts "* relevant configuration entries are storage_mount, read_only_realpath, and read_write_realpath"
    puts "* Storage mount => #{IDB_CONFIG[:storage_mount]}"
    puts "* Current realpath of #{IDB_CONFIG[:storage_mount]} => #{mount_path}"
    puts "* Realpath to compare for read only => #{read_only_path}"
    puts "* Realpath to compare for read and write => #{read_write_path}"
    puts "*******"

  end

end