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
                staging_path: 'uploads/57rbk/test.txt',
                medusa_path: '57rbk_test.txt',
                medusa_uuid: '149603bb-0cad-468b-9ef0-e91023a5d458',
                error: ''}

    # msg_hash = {status: 'ok',
    #             operation: 'ingest',
    #             staging_path: 'uploads/nx6x4/stock_unicorn.jpg',
    #             medusa_path: 'nx6x4_stock_unicorn.jpg',
    #             medusa_uuid: '149603bb-0cad-468b-9ef0-e91023a5d456',
    #             error: ''}

    x.publish("#{msg_hash.to_json}", :routing_key => q.name)

    msg_hash = {status: 'ok',
                operation: 'ingest',
                staging_path: 'uploads/bqz8o/hello.rb',
                medusa_path: 'bqz8o_hello.rb',
                medusa_uuid: '149603bb-0cad-468b-9ef0-e91023a5d459',
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
                staging_path: 'uploads/tbzaq/test.txt',
                medusa_path: '',
                medusa_uuid: '',
                error: 'malformed thingy'}

    x.publish("#{msg_hash.to_json}", :routing_key => q.name)

    conn.close

  end

  desc 'get Medusa RabbitMQ ingest response messages'
  task :get_medusa_ingest_responses => :environment do
    puts "getting message"

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

end