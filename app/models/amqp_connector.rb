# frozen_string_literal: true

require 'singleton'
require 'set'

# Represent AMQP connection and provide convenience methods.
# amqp section of databank.yml can contain any option appropriate for Bunny.new.
class AmqpConnector < Object
  include Singleton

  attr_accessor :connection, :known_queues

  def initialize
    reinitialize
  end

  def reinitialize
    config = (IDB_CONFIG['amqp'] || {}).symbolize_keys
    config[:recover_from_connection_close] = true
    self.known_queues = Set.new
    connection&.close
    connection = Bunny.new(config)
    connection.start
  end

  def clear_queues(*queue_names)
    queue_names.each do |queue_name|
      continue = true
      while continue
        with_message(queue_name) do |msg|
          continue = msg
          puts "#{self.class} clearing: #{msg} from: #{queue_name}" if msg
        end
      end
    end
  end

  def with_channel
    channel = connection.create_channel
    yield channel
  ensure
    channel&.close
  end

  def with_queue(queue_name)
    with_channel do |channel|
      queue = channel.queue(queue_name, durable: true)
      yield queue
    end
  end

  def ensure_queue(queue_name)
    unless known_queues.include?(queue_name)
      with_queue(queue_name) do |queue|
        # no-op, just ensuring queue exists
      end
      known_queues << queue_name
    end
  end

  def with_message(queue_name)
    with_queue(queue_name) do |queue|
      delivery_info, properties, raw_payload = queue.pop
      yield raw_payload
    end
  end

  def with_parsed_message(queue_name)
    with_message(queue_name) do |message|
      json_message = message ? JSON.parse(message) : nil
      yield json_message
    end
  end

  def with_exchange
    with_channel do |channel|
      exchange = channel.default_exchange
      yield exchange
    end
  end

  def send_message(queue_name, message)
    ensure_queue(queue_name)
    with_exchange do |exchange|
      message = message.to_json if message.is_a?(Hash)
      exchange.publish(message, routing_key: queue_name, persistent: true)
    end
  end
end
