require 'active_support/concern'
require 'fileutils'
require 'json'

module MedusaAmqp
  extend ActiveSupport::Concern

  included do
    delegate :incoming_queue, :outgoing_queue, :on_medusa_message, :on_medusa_succeeded_message, :on_medusa_failed_message, :subscribe_to_incoming, to: :class
  end

  module ClassMethods
    def incoming_queue
      IDB_CONFIG['medusa']['incoming_queue']
    end

    def outgoing_queue
      IDB_CONFIG['medusa']['outgoing_queue']
    end

    def on_medusa_message(response)
      response_hash = JSON.parse(response)

      if response_hash.has_key? 'status'
        case response_hash['status']
          when 'ok'
            self.on_medusa_succeeded_message(response_hash)
          when 'error'
            self.on_medusa_failed_message(response_hash)
          else
            raise RuntimeError, "Unrecognized status #{response.status} for medusa ingest response"
        end
      else
        raise RuntimeError, "Unrecognized format for medusa ingest response: #{response.to_yaml}"
      end

    end

    def on_medusa_succeeded_message(response_hash)
      staging_path_arr = (response_hash['staging_path']).split('/')

      ingest_relation = MedusaIngest.where("staging_path = ?", response_hash['staging_path'])
      Rails.logger.warn "ingest_relation"
      Rails.logger.warn ingest_relation.to_yaml
      Rails.logger.warn "response_hash['staging_path']: #{response_hash['staging_path']}"

      if ingest_relation.count > 0

        ingest = ingest_relation.first
        ingest.request_status = response_hash['status'].to_s
        ingest.medusa_path = response_hash['medusa_path']
        ingest.medusa_uuid = response_hash['medusa_uuid']
        ingest.response_time = Time.now.utc.iso8601
        ingest.save!
      else
        Rails.logger.warn "could not find ingest record for medusa succeeded message: #{response_hash['staging_path']}"
      end

      case staging_path_arr[0]
        when 'uploads'
          datafile = Datafile.find_by_web_id(staging_path_arr[1])
          if datafile && datafile.binary && datafile.binary.file
            datafile.medusa_path = response_hash['medusa_path']
            datafile.medusa_id = response_hash['medusa_uuid']
            if File.exists?("#{IDB_CONFIG['medusa']['medusa_path_root']}/#{datafile.medusa_path}") &&  datafile.binary && FileUtils.identical?(datafile.binary.path, "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{datafile.medusa_path}")
              datafile.remove_binary!
              datafile.save
            else
              Rails.logger.warn "Copy unverified for medusa ingest response #{response.to_yaml}"
            end
          else
            Rails.logger.warn "Did not find datafile binary, staging_path_arr: #{staging_path_arr.to_yaml}"
          end
        when 'agreements'
          # ignore for now
        else
          Rails.logger.warn "Unrecognized staging_path in medusa ingest response #{response.to_yaml}"
      end

    end

    def on_medusa_failed_message(response_hash)
      ingest = MedusaIngest.where(staging_path: response.staging_path)
      if ingest
        Rails.logger.warn "medusa failed message:"
        Rails.logger.warn ingest.to_yaml
        ingest.request_status = response.status
        ingest.error_text = response.error
        ingest.response_time = Time.now.utc.iso8601
        ingest.save
      else
        Rails.logger.warn "could not find file for medusa failure message: #{response.staging_path}"
      end
    end

  end

  def send_medusa_ingest_message(staging_path)
    AmqpConnector.instance.send_message(self.outgoing_queue, create_medusa_ingest_message(staging_path))
  end

  def create_medusa_ingest_message(staging_path)
    {"operation":"ingest", "staging_path":"#{staging_path}"}
  end

end