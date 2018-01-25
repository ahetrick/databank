require 'rake'
require 'bunny'
require 'json'

namespace :medusa do

  desc 'get a RabbitMQ ingest response message'
  task :get_ingest_response_msg => :environment do
    AmqpConnector.instance.with_message(IDB_CONFIG['medusa']['incoming_queue'], create_medusa_ingest_message(staging_path)) do |payload|
    end
  end

  desc 'simulate RabbitMQ ok response from Medusa'
  task :send_ok => :environment do
    puts "sending message"

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    Rails.logger.warn(config.to_yaml)

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
                staging_path: 'uploads/file.txt',
                medusa_path: 'file.txt',
                medusa_uuid: '149603bb-0cad-468b-9ef0-e91023a5d460',
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
                staging_path: 'uploads/test.txt',
                medusa_path: '',
                medusa_uuid: '',
                error: 'malformed thingy'}

    x.publish("#{msg_hash.to_json}", :routing_key => q.name)

    conn.close

  end

  desc 'get Medusa RabbitMQ ingest response messages'
  task :get_medusa_ingest_responses => :environment do

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q = ch.queue("medusa_to_idb", :durable => true)
    x = ch.default_exchange

    has_payload = true

    while has_payload
      delivery_info, properties, payload = q.pop
      if payload.nil?
        has_payload = false
      else
        MedusaIngest.on_medusa_message(payload)
      end
    end
    conn.close

  end

  desc 'update medusa_path of datafile from ingest'
  task :update_paths => :environment do
    datafiles = Datafile.all
    datafiles.each do |df|

      if !df.binary && !df.medusa_path
        puts "web_id: #{df.web_id}"
        puts "no binary or no medusa_path"
        ingest = MedusaIngest.find_by_idb_identifier(df.web_id)
        if ingest
          puts "has ingest"
          df.medusa_path = ingest.medusa_path
          df.save
        else
          puts "has no ingest"
        end

      elsif df.binary && !df.medusa_path
        puts "web_id: #{df.web_id}"
        puts "binary but no medusa path"
        ingest = MedusaIngest.find_by_idb_identifier(df.web_id)
        if ingest
          puts "has ingest"

          effective_binary_path_str = df.binary.path.to_s
          effective_medusa_path_str = "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{ingest.medusa_path}".to_s

          puts "binary: #{effective_binary_path_str}"
          puts "medusa: #{effective_medusa_path_str}"

          if File.exists?(effective_medusa_path_str) && File.exists?(effective_binary_path_str) && FileUtils.identical?(Pathname.new(effective_medusa_path_str), Pathname.new(effective_binary_path_str))
            df.medusa_path = ingest.medusa_path
            df.medusa_id = ingest.medusa_uuid
            df.remove_binary!
            df.save
          else
            puts "first pass of file validation failed"
          end

          if File.exists?(effective_medusa_path_str) && !File.exists?(effective_binary_path_str)
            df.medusa_path = ingest.medusa_path
            df.medusa_id = ingest.medusa_uuid
            df.remove_binary!
            df.save
          else
            puts "missing binary file but file exists in Medusa"
          end

        else
          puts "has no ingest for web_id: #{df.web_id}"
        end
      end
    end

    puts "* * *   DONE WITH DATAFIES, STARTING RECORDFILES  * * *"

    recordfiles = Recordfile.all
    recordfiles.each do |df|

      if !df.binary && !df.medusa_path
        puts "web_id: #{df.web_id}"
        puts "no binary or no medusa_path"
        ingest = MedusaIngest.find_by_idb_identifier(df.web_id)
        if ingest
          puts "has ingest"
          df.medusa_path = ingest.medusa_path
          df.save
        else
          puts "has no ingest"
        end

      elsif df.binary && !df.medusa_path
        puts "web_id: #{df.web_id}"
        puts "binary but no medusa path"
        ingest = MedusaIngest.find_by_idb_identifier(df.web_id)
        if ingest
          puts "has ingest"

          effective_binary_path_str = df.binary.path.to_s
          effective_medusa_path_str = "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{ingest.medusa_path}".to_s

          puts "binary: #{effective_binary_path_str}"
          puts "medusa: #{effective_medusa_path_str}"

          if File.exists?(effective_medusa_path_str) && File.exists?(effective_binary_path_str) && FileUtils.identical?(Pathname.new(effective_medusa_path_str), Pathname.new(effective_binary_path_str))
            df.medusa_path = ingest.medusa_path
            df.medusa_id = ingest.medusa_uuid
            df.remove_binary!
            df.save
          else
            puts "first pass of file validation failed"
          end

          if File.exists?(effective_medusa_path_str) && !File.exists?(effective_binary_path_str)
            df.medusa_path = ingest.medusa_path
            df.medusa_id = ingest.medusa_uuid
            df.remove_binary!
            df.save
          else
            puts "missing binary file but file exists in Medusa"
          end

        else
          puts "has no ingest for web_id: #{df.web_id}"
        end
      end
    end
  end

  desc 'resend failed medusa messages'
  task :retry_failed => :environment do
    failed_ingests = MedusaIngest.where(request_status: 'error')
    failed_ingests.each do |ingest|

      ingest.request_status = 'resent'
      ingest.error_text = ''
      ingest.response_time = ''
      ingest.send_medusa_ingest_message(ingest.staging_path)
      ingest.save

    end
  end

  desc 'retroactively set medusa_dataset_dir in dataset if it exist in ingest'
  task :retry_set_dir => :environment do
    ingests = MedusaIngest.where.not(medusa_dataset_dir: nil)
    ingests.each do |ingest|
      if ingest.idb_class == 'datafile'
        datafile = Datafile.find_by_web_id(ingest.idb_identifier)

        dataset = Dataset.where(id: datafile.dataset_id).first

        unless dataset
          Rails.logger.warn "dataset not found for ingest #{ingest.to_yaml}"
        end

        medusa_dataset_dir_json = JSON.parse((ingest.medusa_dataset_dir).gsub("'",'"').gsub('=>',':'))

        if dataset && (!dataset.medusa_dataset_dir || dataset.medusa_dataset_dir == '')
          dataset.medusa_dataset_dir = medusa_dataset_dir_json['url_path']
          dataset.save
        end


      end
    end
  end

  desc 'resend messages not sent'
  task :retry_medusa_sends => :environment do
    puts 'not yet implemented'
  end
end
