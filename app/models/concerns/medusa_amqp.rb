require 'active_support/concern'

module MedusaAmqp
  extend ActiveSupport::Concern

  included do
    delegate :incoming_queue, :outgoing_queue, to: :class
  end

  module ClassMethods
    def incoming_queue
      IDB_CONFIG['medusa']['incoming_queue']
    end

    def outgoing_queue
      IDB_CONFIG['medusa']['outgoing_queue']
    end

  end

  def send_medusa_ingest_message(staging_path)
    AmqpConnector.instance.send_message(self.outgoing_queue, create_medusa_ingest_message(staging_path))
  end

  def create_medusa_ingest_message(staging_path)
    {"operation":"ingest", "staging_path":"#{staging_path}"}
  end

  def on_medusa_succeeded_message(response)
    staging_path_arr = response.(staging_path).split('/')
    ingest = MedusaIngest.where(staging_path: response.staging_path)
    if ingest
      ingest.request_status = response.status
      ingest.medusa_path = response.medusa_path
      ingest.medusa_uuid = response.medusa_uuid
      ingest.response_time = Time.now.utc.iso8601
      ingest.save
    else
      Rails.logger.warn "could not find file for medusa failure message: #{response.staging_path}"
    end
    case staging_path_arr[0]
      when 'uploads'
        datafile = Datafile.find_by_web_id(staging_path_arr[1])
        if datafile
          datafile.medusa_path = response.medusa_path
          # TODO: confirm medusa file exists
          datafile.binary_size = datafile.binary.size
          datafile.binary_name = datafile.binary.file.filename
          datafile.medusa_id = response.medusa_uuid
          datafile.save
          # TODO: remove binary
        end
      else
        Rails.logger.warn "Unrecognized staging_path in medusa ingest response #{response.to_yaml}"
    end

  end

  def on_medusa_failed_message(response)
    ingest = MedusaIngest.where(staging_path: response.staging_path)
    if ingest
      ingest.request_status = response.status
      ingest.error_text = response.error
      ingest.response_time = Time.now.utc.iso8601
    else
      Rails.logger.warn "could not find file for medusa failure message: #{response.staging_path}"
    end
  end

  def on_medusa_message(response)
    case response.status
      when 'ok'
        on_medusa_succeeded_message(response)
      when 'error'
        on_medusa_failed_message(response)
      else
        raise RuntimeError, "Unrecognized AMQP status #{response.status} for medusa ingest response"
    end
  end

end