class ProcessorClient < ActiveRecord::Base

  def self.incoming_queue
    IDB_CONFIG['processor']['incoming_queue']
  end

  def self.outgoing_queue
    IDB_CONFIG['processor']['outgoing_queue']
  end

  def self.on_processor_message(response)
    response_hash = JSON.parse(response)
    if response_hash.has_key?('operation')
      operation_parts = response_hash['operation'].split('.')
      if operation_parts.length == 2
        if operation_parts[0] == 'NestedItems'
          process_items_message(response_hash)
        elsif operation_parts[0] == 'Peek'
          process_peek_message(response_hash)
        else
          Rails.logger.warn("invalid incoming message: #{response}")
        end
      end

    else
      Rails.logger.warn("invalid incoming message: #{response}")
    end
  end

  def self.process_peek_message(response_hash)

    operation_parts = response_hash['operation'].split('.')
    if operation_parts[1] == 'add'
      if response_hash.has_key?('peek_text') &&
          response_hash.has_key?('peek_type') &&
          response_hash.has_key?('datafile_id')
        datafile = Datafile.find(response_hash['datafile_id'])
        if datafile
          datafile.peek_type = response_hash['peek_type']
          datafile.peek_text = response_hash['peek_text']
          datafile.save
        end
      end
    elsif operation_parts[1] == 'remove'
      raise("not yet implemented")
    else
      Rails.logger.warn("invalid peek operation for incoming message: #{response_hash}")
    end
  end

  def self.process_item_message(response_hash)

    #TODO: create peek text

    operation_parts = response_hash['operation'].split('.')
    if operation_parts[1] == 'add'
      if response_hash.has_key?("datafile_id") &&
          response_hash.has_key?("parent_id") &&
          response_hash.has_key?("item_name") &&
          response_hash.has_key?("media_type") &&
          response_hash.has_key?("size") &&
          response_hash.has_key?("is_directory")
        datafile = Datafile.find(response_hash['datafile_id'])
        if datafile
          NestedItem.create(
              :datafile_id => response_hash['datafile_id'],
              :parent_id => response_hash['parent_id'],
              :item_name => response_hash['item_name'],
              :media_type => response_hash['media_type'],
              :is_directory => response_hash['is_directory'],
              :size => response_hash['size'].to_i
          )
        end
      end
    elsif operation_parts[1] == 'remove'
      raise("not yet implemented")
    else
      Rails.logger.warn("invalid nested item operation for incoming message: #{response_hash}")
    end
  end

  def send_processor_message(message)
    AmqpConnector.instance.send_message(ProcessorClient.outgoing_queue, message)
  end

end