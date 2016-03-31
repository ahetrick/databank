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

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q  = ch.queue("medusa_to_idb", :durable => true)
    x  = ch.default_exchange

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
    q  = ch.queue("medusa_to_idb", :durable => true)
    x  = ch.default_exchange

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
    q  = ch.queue("medusa_to_idb", :durable => true)
    x  = ch.default_exchange

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
      if !df.binary  && !df.medusa_path
        puts "no binary or no medusa_path"
        ingest = MedusaIngest.find_by_idb_identifier(df.web_id)
        if ingest
          puts "has ingest"
          df.medusa_path = ingest.medusa_path
          df.save
        else
          puts "has no ingest"
        end
      end
    end
    datafiles.each do |df|
      if df.binary  && !df.medusa_path
        puts "binary but no medusa path"
        ingest = MedusaIngest.find_by_idb_identifier(df.web_id)
        if ingest
          puts "has ingest"
          df.medusa_path = ingest.medusa_path
          df.medusa_uuid = ingest.medusa_uuid
          df.remove_binary!
          df.save
        else
          puts "has no ingest"
        end
      end
    end
  end

end