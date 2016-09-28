class MedusaIngest < ActiveRecord::Base

  def self.incoming_queue
    IDB_CONFIG['medusa']['incoming_queue']
  end

  def self.outgoing_queue
    IDB_CONFIG['medusa']['outgoing_queue']
  end

  def self.on_medusa_message (response)
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

  def self.send_dataset_to_medusa(dataset, old_publication_state)

    # create or confirm dataset_staging directory for dataset
    dataset_dirname = "DOI-#{(dataset.identifier).parameterize}"
    staging_dir = "#{IDB_CONFIG[:staging_root]}/#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}"

    FileUtils.mkdir_p "#{staging_dir}/system"
    FileUtils.chmod "u=wrx,go=rx", File.dirname(staging_dir)

    file_time = Time.now.strftime('%Y-%m-%d_%H-%M')
    description_xml = dataset.to_datacite_xml
    File.open("#{staging_dir}/system/description.#{file_time}.xml", "w") do |description_file|
      description_file.puts(description_xml)
    end
    FileUtils.chmod 0755, "#{staging_dir}/system/description.#{file_time}.xml"

    medusa_ingest = MedusaIngest.new
    staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/description.#{file_time}.xml"
    medusa_ingest.staging_path = staging_path
    medusa_ingest.idb_class = 'description'
    medusa_ingest.idb_identifier = dataset.key
    medusa_ingest.send_medusa_ingest_message(staging_path)
    medusa_ingest.save

    #if old_publication_state == Databank::PublicationState::DRAFT && !dataset.is_test?

    # put test datasets in Medusa -- may reconsider later.

    if old_publication_state == Databank::PublicationState::DRAFT

      FileUtils.mkdir_p "#{staging_dir}/dataset_files"

      dataset.datafiles.each do |datafile|

        datafile.binary_name = datafile.binary.file.filename
        datafile.binary_size = datafile.binary.size
        medusa_ingest = MedusaIngest.new
        full_path = datafile.binary.path
        full_staging_path = "#{staging_dir}/dataset_files/#{datafile.binary_name}"
        #make symlink
        FileUtils.ln(full_path, full_staging_path)
        FileUtils.chmod "u=wrx,go=rx", full_staging_path
        #staging_path is different from full_staging_path because it is relative to a directory known to Medusa
        staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/dataset_files/#{datafile.binary_name}"
        Rails.logger.warn "staging path: #{staging_path}"
        medusa_ingest.staging_path = staging_path
        medusa_ingest.idb_class = 'datafile'
        medusa_ingest.idb_identifier = datafile.web_id
        medusa_ingest.send_medusa_ingest_message(staging_path)
        medusa_ingest.save
      end
      if File.exist?("#{IDB_CONFIG[:agreements_root_path]}/#{dataset.key}/deposit_agreement.txt")
        medusa_ingest = MedusaIngest.new
        full_path = "#{IDB_CONFIG[:agreements_root_path]}/#{dataset.key}/deposit_agreement.txt"
        full_staging_path = "#{staging_dir}/system/deposit_agreement.txt"
        # make symlink
        FileUtils.ln(full_path, full_staging_path)
        FileUtils.chmod "u=wrx,go=rx", full_staging_path
        # point to link for path
        staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/deposit_agreement.txt"
        medusa_ingest.staging_path = staging_path
        medusa_ingest.idb_class = 'agreement'
        medusa_ingest.idb_identifier = dataset.key
        medusa_ingest.send_medusa_ingest_message(staging_path)
        medusa_ingest.save
      else
        raise "deposit agreement file not found for #{dataset.key}"
      end

    end

    serialization_json = (dataset.recovery_serialization).to_json
    File.open("#{staging_dir}/system/serialization.#{file_time}.json", "w") do |serialization_file|
      serialization_file.puts(serialization_json)
    end
    FileUtils.chmod 0755, "#{staging_dir}/system/serialization.#{file_time}.json"

    medusa_ingest = MedusaIngest.new
    staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/serialization.#{file_time}.json"
    medusa_ingest.staging_path = staging_path
    medusa_ingest.idb_class = 'serialization'
    medusa_ingest.idb_identifier = dataset.key
    medusa_ingest.send_medusa_ingest_message(staging_path)
    medusa_ingest.save


    changelog_json = (dataset.full_changelog).to_json
    File.open("#{staging_dir}/system/changelog.#{file_time}.json", "w") do |changelog_file|
      changelog_file.write(changelog_json)
    end
    FileUtils.chmod 0755, "#{staging_dir}/system/changelog.#{file_time}.json"
    medusa_ingest = MedusaIngest.new
    staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/changelog.#{file_time}.json"
    medusa_ingest.staging_path = staging_path
    medusa_ingest.idb_class = 'changelog'
    medusa_ingest.idb_identifier = dataset.key
    medusa_ingest.send_medusa_ingest_message(staging_path)
    medusa_ingest.save
  end


  def self.on_medusa_succeeded_message(response_hash)
    staging_path_arr = (response_hash['staging_path']).split('/')
    # Rails.logger.warn response_hash['staging_path']
    # Rails.logger.warn "item_root_dir: #{response_hash['item_root_dir']}"

    ingest_relation = MedusaIngest.where("staging_path = ?", response_hash['staging_path'])

    if ingest_relation.count > 0

      ingest = ingest_relation.first
      ingest.request_status = response_hash['status'].to_s
      ingest.medusa_path = response_hash['medusa_path']
      ingest.medusa_uuid = response_hash['medusa_uuid']
      ingest.medusa_dataset_dir = response_hash['item_root_dir']
      ingest.response_time = Time.now.utc.iso8601
      ingest.save!

      if File.exists?("#{IDB_CONFIG['medusa']['medusa_path_root']}/#{response_hash['medusa_path']}") && FileUtils.identical?("#{IDB_CONFIG[:staging_root]}/#{response_hash['staging_path']}", "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{response_hash['medusa_path']}")

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

          if datafile && datafile.binary
            datafile.medusa_path = ingest.medusa_path
            datafile.medusa_id = ingest.medusa_uuid
            datafile.remove_binary!
            datafile.save
          else
            Rails.logger.warn "Datafile already gone for ingest #{ingest.id}"
          end
        end
        # delete file or symlink from staging directory
        File.delete("#{IDB_CONFIG[:staging_root]}/#{response_hash['staging_path']}")
      else
        Rails.logger.warn "did not delete file because Medusa copy does not exist or is not verified for #{ingest.to_yaml}"
      end

    else
      Rails.logger.warn "could not find ingest record for medusa succeeded message: #{response_hash['staging_path']}"
    end
  end

  def self.on_medusa_failed_message(response_hash)
    Rails.logger.warn "medusa failed message:"
    Rails.logger.warn response_hash.to_yaml
    ingestRelation = MedusaIngest.where(staging_path: response_hash['staging_path'])
    if ingestRelation.count > 0
      ingest = ingestRelation.first
      ingest.request_status = response_hash['status']
      ingest.error_text = response_hash['error']
      ingest.response_time = Time.now.utc.iso8601
      ingest.save
    else
      Rails.logger.warn "could not find file for medusa failure message: #{response_hash['staging_path']}"
    end
  end

  def send_medusa_ingest_message(staging_path)
    AmqpConnector.instance.send_message(MedusaIngest.outgoing_queue, create_medusa_ingest_message(staging_path))
  end

  def create_medusa_ingest_message(staging_path)
    {"operation" => "ingest", "staging_path" => "#{staging_path}"}
  end

end
