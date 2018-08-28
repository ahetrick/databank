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
      #Rails.logger.warn("medusa message resopnse: #{response_hash.to_yaml}")
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

  def self.send_dataset_to_medusa(dataset)

    # TODO: adapt to medusa_storage, meanwhile skip
    return true

    # put test datasets in Medusa -- may reconsider later.
    # if Rails.env.test?
    #   return true
    # end

    ### skip datafiles already ingested, but send new system files ###

    file_time = Time.now.strftime('%Y-%m-%d_%H-%M')
    dataset_dirname = "DOI-#{(dataset.identifier).parameterize}"

    # START description file
    # always send a description file
    description_xml = dataset.to_datacite_xml
    description_key = "#{dataset_dirname}/system/description.#{file_time}.xml"
    Application.storage_manager.draft_root.write_string_to(description_key, description_xml)
    medusa_ingest = MedusaIngest.new
    medusa_ingest.staging_key = description_key
    medusa_ingest.target_key = description_key
    medusa_ingest.idb_class = 'description'
    medsua_ingest.idb_identifier = dataset.key
    medusa_ingest.save
    medusa_ingest.send_medusa_ingest_message
    # END description file

    # START datafiles
    # send existing draft datafiles not yet in medusa
    dataset.datafiles.each do |datafile|

      in_medusa = false # guess that datafile is not yet in medusa, but check and handle

      dataset_dirname = "DOI-#{(dataset.identifier).parameterize}"
      datafile_target_key = "#{dataset_dirname}/dataset_files/#{datafile.binary_name}"

      if Application.storage_manager.medusa_root.exist?(datafile_target_key)

        if datafile&.storage_root == 'draft' && datafile&.storage_key != ''

          # If the binary object also exists in draft system, delete duplicate.
          #  Can't do full equivalence check (S3 etag is not always MD5), so check sizes.
          if Application.storage_manager.draft_root.exist?(datafile.storage_key)
            draft_size = Application.storage_manager.draft_root.size(datafile.storage_key)
            medusa_size = Application.storage_manager.medusa_root.size(datafile_storage_key)

            if draft_size == medusa_size
              # If the ingest into Medusa was successful,
              # delete redundant binary object
              # and update Illinois Data Bank datafile record
              Application.storage_manager.draft_root.delete_content(dataset.storage_key)
              in_medusa = true
            else
              exception_string("Datafile exists in both draft and medusa storage systems, but the sizes are different. Dataset: #{dataset.key}, Datafile: #{datafile.web_id}")
              notification = DatabankMailer.error(exception_string)
              notification.deliver_now
            end
          else
            in_medusa = true
          end

          if in_medusa
            datafile.storage_root = 'medusa'
            datafile.storage_key = datafile_target_key
            datafile.save
          end

        elsif datafile&.storage_root == 'draft' && datafile&.storage_key != '' && Application.storage_manager.draft_root.exist?(datafile.storage_key)

          # send medusa ingest request if binary exists in draft storage but not medusa storage
          medusa_ingest = MedusaIngest.new
          medusa_ingest.staging_key = datafile.storage_key
          medusa_ingest.target_key = datafile_target_key
          medusa_ingest.idb_class = 'datafile'
          medusa_ingest.idb_identifier = datafile.web_id
          medusa_ingest.save
          medusa_ingest.send_medusa_ingest_message
        else
          exception_string("Binary object not found for Dataset: #{dataset.key}, Datafile: #{datafile.web_id}")
          notification = DatabankMailer.error(exception_string)
          notification.deliver_now
        end
      end

    end
    # END datafiles

    # START deposit agreement
    draft_exists = Application.storage_manager.draft_root.exist?(dataset.agreement_key)
    medusa_exists = Application.storage_manager.medusa_root.exist?(dataset.agreement_key)

    if draft_exists && !medusa_exists
      medusa_ingest = MedusaIngest.new
      medusa_ingest.staging_key = dataset.agreement_key
      medusa_ingest.target_key = dataset.agreement_key
      medusa_ingest.idb_class = 'agreement'
      medusa_ingest.idb_identifier = dataset.key
      medusa_ingest.save
      medusa_ingest.send_medusa_ingest_message
    elsif draft_exists && medusa_exists
      draft_size = Application.storage_manager.draft_root.size(dataset.agreement_key)
      medusa_size = Application.storage_manager.medusa_root.size(dataset.agreement_key)
      if draft_size == medusa_size
        Application.storage_manager.draft_root.delete_content(dataset.agreement_key)
      else
        exception_string("Agreement file exists in both draft and medusa storage systems, but the sizes are different. Dataset: #{dataset.key}.")
        notification = DatabankMailer.error(exception_string)
        notification.deliver_now
      end
    elsif !draft_exists && !medusa_exists
      exception_string("Deposit agreement not found for Dataset: #{dataset.agreement_key}.")
      notification = DatabankMailer.error(exception_string)
      notification.deliver_now
    end
    # END deposit agreement

    # START serialization
    # always send a serialization
    serialization_json = (dataset.recovery_serialization).to_json
    serialization_key = "#{dataset_dirname}/system/serialization.#{file_time}.json"
    Application.storage_manager.draft_root.write_string_to(serialization_key, serialization_json)
    medusa_ingest = MedusaIngest.new
    medusa_ingest.staging_key = serialization_key
    medusa_ingest.target_key = serialization_key
    medusa_ingest.idb_class = 'serialization'
    medusa_ingest.idb_identifier = dataset.key
    medusa_ingest.send_medusa_ingest_message
    medusa_ingest.save
    # END serialization

    # START changelog
    # always send a changelog
    changelog_json = (dataset.full_changelog).to_json
    changelog_key = "#{dataset_dirname}/system/changelog.#{file_time}.json"
    Application.storage_manager.draft_root.write_string_to(changelog_key, changelog_json)
    medusa_ingest = MedusaIngest.new
    medusa_ingest.staging_key = changelog_key
    medusa_ingest.target_key = changelog_key
    medusa_ingest.idb_class = 'changelog'
    medusa_ingest.idb_identifier = dataset.key
    medusa_ingest.send_medusa_ingest_message
    medusa_ingest.save
    # END changelog

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
      ingest.medusa_uuid = response_hash['uuid']
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

          if datafile&.binary
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
        Rails.logger.warn "did not delete file because Medusa copy does not exist or is not verified for ingest #{ingest.id}"
        Rails.logger.warn "staging path: #{IDB_CONFIG[:staging_root]}/#{response_hash['staging_path']}"
        Rails.logger.warn "medusa path: #{IDB_CONFIG['medusa']['medusa_path_root']}/#{response_hash['medusa_path']}"
      end
    else
      Rails.logger.warn "could not find ingest record for medusa succeeded message: #{response_hash['staging_path']}"
    end
  end

  def self.on_medusa_failed_message(response_hash)
    Rails.logger.warn "medusa failed message:"
    Rails.logger.warn response_hash.to_yaml
    ingest_relation = MedusaIngest.where(staging_path: response_hash['staging_path'])
    if ingest_relation.count > 0
      ingest = ingest_relation.first
      ingest.request_status = response_hash['status']
      ingest.error_text = response_hash['error']
      ingest.response_time = Time.now.utc.iso8601
      ingest.save

      if response_hash['status'] != 'ok'
        error_string = "Problem ingesting #{response_hash['staging_path']} into Medusa : #{response_hash['error']}"
        notification = DatabankMailer.error(error_string)
        notification.deliver_now
      end

    else
      Rails.logger.warn "could not find file for medusa failure message: #{response_hash['staging_path']}"
    end
  end

  def send_medusa_ingest_message()
    AmqpConnector.instance.send_message(MedusaIngest.outgoing_queue, medusa_ingest_message)
  end

  def medusa_ingest_message()
    {"operation" => "ingest",
     "draft_key" => self.draft_key,
     "target_key" => self.target_key,
     "pass_hash" => {class: self.idb_class, identifier: self.idb_identifier} }
  end

end
