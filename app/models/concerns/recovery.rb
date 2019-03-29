module Recovery
  extend ActiveSupport::Concern

  class_methods do
    def serializations_from_medusa

      directories = Dir.entries(IDB_CONFIG['medusa']['medusa_path_root'])
      serializations = Array.new

      if directories && directories.length > 2 # more than for . and ..
        directories = directories.select { |directory| directory.to_s.include? "DOI" }

        directories.each do |directory|
          serializations.append(Dataset.get_serialzation_json_from_medusa(directory.gsub("DOI-10-", "10.")))
        end
      end
      return serializations
    end

    def get_serialzation_json_from_medusa(identifier)

      # assumes identifier in the format stored in a dataset object
      # rough test: starts with 10.

      dirname = nil
      if identifier.start_with?('10.')
        dirname = "#{IDB_CONFIG['medusa']['medusa_path_root']}/DOI-#{identifier.parameterize}"

        if Dir.exists? dirname
          if Dir.exists?("#{dirname}/system")
            serialization_files = Dir["#{dirname}/system/*"].select { |entry| entry.include? "serialization" }

            if serialization_files.length > 0

              if serialization_files.length == 1
                # FIRST BRANCH OF HAPPY PATH ENDS HERE
                return IO.read(serialization_files[0])
              else

                date_array = Array.new
                serialization_files.each do |file|
                  file_parts = file.split(".")
                  timestring = file_parts[1]
                  datetime_parts = timestring.split("_")
                  date_parts = datetime_parts[0].split("-")
                  time_parts = datetime_parts[1].split("-")
                  date_array.append(DateTime.new(date_parts[0].to_i, date_parts[1].to_i, date_parts[2].to_i, time_parts[0].to_i, time_parts[1].to_i, 0))
                end
                latest_datetime = date_array.max
                datetime_string = latest_datetime.strftime('%Y-%m-%d_%H-%M')
                latest_serialization_file = "#{dirname}/system/serialization.#{datetime_string}.json"

                # SECOND BRANCH OF HAPPY PATH ENDS HERE
                return IO.read(latest_serialization_file)

              end


            else
              return %Q[{'status':'error', 'error':"no serialization files found in: #{dirname}/system" }]

            end
          else
            return %Q[{'status':'error', 'error':"DIRECTORY NOT FOUND: #{dirname}/system" }]
          end

        else
          return %Q[{'status':'error', 'error':"DIRECTORY NOT FOUND: #{dirname}" }]
        end

      else
        raise("invalid identifier")
      end

      return %Q[{'status':'error', 'error':'unexpected error'}]

    end

    def recover_audit_record(change, agent_id, event_id)
      existing_record_relation = Audited::Adapters::ActiveRecord::Audit.where(id:change['id'])

      if existing_record_relation.count > 0

        existing_record = existing_record_relation.first

        existing_record.user_id = agent_id

        if change['auditable_type'] == "Dataset"
          old_dataset_id = change['auditable_id']
          map = RestorationIdMap.find_by(event_id: event_id, id_class: "Dataset", old_id: old_dataset_id)
          raise("no map found for #{event_id} #{change.to_yaml}") unless map
          existing_record.save
        else
          old_dataset_id = change['associated_id']

          dataset_map = RestorationIdMap.find_by(event_id: event_id, id_class: 'Dataset', old_id: old_dataset_id)
          raise("no map found for #{event_id} #{change.to_yaml}") unless dataset_map
          new_dataset_id = dataset_map.new_id
          existing_record.associated_id = new_dataset_id

          resource_map = RestorationIdMap.find_by(event_id: event_id, id_class: change['auditable_type'], old_id: change['auditable_id'])
          if resource_map
            new_resource_id = resource_map.new_id
            existing_record.auditable_id = new_resource_id
          #else
            # assume resource was deleted
          end

        end

        existing_record.save

      else
        add_audit_record(change, agent_id, event_id)
      end

    end

    def add_audit_record(change, agent_id, event_id)

      existing_record_relation = Audited::Adapters::ActiveRecord::Audit.where(id:change['id'])

      if existing_record_relation.count == 0

        change['user_id'] = agent_id

        #Rails.logger.warn change

        new_change_record = Audited::Adapters::ActiveRecord::Audit.create(change)

        if change['auditable_type'] == "Dataset"
          old_dataset_id = change['auditable_id']
          map = RestorationIdMap.find_by(restoration_event_id: event_id, id_class: "Dataset", old_id: old_dataset_id)
          raise("no map found for #{event_id}#{change.to_yaml}") unless map
          new_dataset_id = map.new_id
          new_change_record.auditable_id = new_dataset_id

        else
          old_dataset_id = change['associated_id']

          dataset_map = RestorationIdMap.find_by(restoration_event_id: event_id, id_class: "Dataset", old_id: old_dataset_id)
          raise("no map found for #{event_id} #{change.to_yaml}") unless dataset_map
          new_dataset_id = dataset_map.new_id
          new_change_record.associated_id = new_dataset_id

          resource_map = RestorationIdMap.find_by(restoration_event_id: event_id, id_class: change['auditable_type'], old_id: change['auditable_id'])
          if resource_map
            new_resource_id = resource_map.new_id
            new_change_record.auditable_id = new_resource_id
          #else
            #assume resource was deleted
          end
          
        end

        new_change_record.save
        #Rails.logger.warn "change #{change['id']} created at #{new_change_record.created_at}."
        #Rails.logger.warn new_change_record.to_json

      else
        raise("record exists")
      end

    end

    def get_changelog_from_medusa(identifier)
      # assumes identifier in the format stored in a dataset object
      # rough test: starts with 10.

      raise("missing identifier") unless identifier

      dirname = nil
      if identifier.start_with?('10.')
        dirname = "#{IDB_CONFIG['medusa']['medusa_path_root']}/DOI-#{identifier.parameterize}"

        if Dir.exists? dirname
          if Dir.exists?("#{dirname}/system")
            changelog_files = Dir["#{dirname}/system/*"].select { |entry| entry.include? "changelog" }

            if changelog_files.length > 0

              if changelog_files.length == 1

                # FIRST BRANCH OF HAPPY PATH ENDS HERE
                return IO.read(changelog_files[0])
              else

                date_array = Array.new
                changelog_files.each do |file|
                  file_parts = file.split(".")
                  timestring = file_parts[1]
                  datetime_parts = timestring.split("_")
                  date_parts = datetime_parts[0].split("-")
                  time_parts = datetime_parts[1].split("-")
                  date_array.append(DateTime.new(date_parts[0].to_i, date_parts[1].to_i, date_parts[2].to_i, time_parts[0].to_i, time_parts[1].to_i, 0))
                end
                latest_datetime = date_array.max
                datetime_string = latest_datetime.strftime('%Y-%m-%d_%H-%M')
                latest_changelog_files = "#{dirname}/system/changelog.#{datetime_string}.json"

                # SECOND BRANCH OF HAPPY PATH ENDS HERE
                return IO.read(latest_changelog_files)

              end


            else
              return %Q[{'status':'error', 'error':"no changelog files found in: #{dirname}/system" }]

            end
          else
            return %Q[{'status':'error', 'error':"DIRECTORY NOT FOUND: #{dirname}/system" }]
          end

        else
          return %Q[{'status':'error', 'error':"DIRECTORY NOT FOUND: #{dirname}" }]
        end

      else
        raise("invalid identifier")
      end

      return %Q[{'status':'error', 'error':'unexpected error'}]
    end

    def restore_db_from_serialization(serialization_json, event_id)

      serialization_hash = JSON.parse(serialization_json, {quirks_mode: true})

      identifier_to_restore = serialization_hash['idb_dataset']['dataset']['identifier']
      raise("record already exists in database") if Dataset.exists?(identifier: identifier_to_restore)

      restore_dataset_hash = serialization_hash['idb_dataset']['dataset']
      dataset_old_id = restore_dataset_hash['id']
      restore_dataset_hash.delete('id')
      restore_dataset_hash.delete('publication_year')
      restore_dataset_hash.delete('has_datacite_change')
      #restore_dataset_hash.delete('created_at')
      restore_dataset_hash.delete('updated_at')
      restored_dataset = Dataset.create(restore_dataset_hash)
      RestorationIdMap.create(restoration_event_id: event_id, id_class: "Dataset", old_id: dataset_old_id, new_id: restored_dataset.id)

      serialization_hash['idb_dataset']['creators'].each do |creator|
        creator_old_id = creator['id']
        creator.delete('id')
        creator['dataset_id'] = restored_dataset.id
        #creator.delete('created_at')
        creator.delete('updated_at')
        creator.delete('row_order')
        restored_creator = restored_dataset.creators.build(creator)
        restored_creator.save

        RestorationIdMap.create(restoration_event_id: event_id, id_class: "Creator", old_id: creator_old_id, new_id: restored_creator.id)
      end

      restored_dataset.save

      serialization_hash['idb_dataset']['datafiles'].each do |datafile|

        datafile_old_id = datafile['id']
        datafile.delete('id')
        datafile['dataset_id'] = restored_dataset.id
        # datafile.delete('created_at')
        datafile.delete('updated_at')
        restored_datafile = restored_dataset.datafiles.build(datafile)
        restored_datafile.save
        RestorationIdMap.create(restoration_event_id: event_id, id_class: "Datafile", old_id: datafile_old_id, new_id: restored_datafile.id)
      end

      #restore_materials_hash = Array.new
      serialization_hash['idb_dataset']['materials'].each do |material|
        material_old_id = material['id']
        material.delete('id')
        material['dataset_id'] = restored_dataset.id
        #material.delete('created_at')
        material.delete('updated_at')
        restored_material = restored_dataset.related_materials.build(material)
        restored_material.save
        RestorationIdMap.create(restoration_event_id: event_id, id_class: "RelatedMaterial", old_id: material_old_id, new_id: restored_material.id)
      end

      serialization_hash['idb_dataset']['funders'].each do |funder|
        funder_old_id = funder['id']
        funder.delete('id')
        funder['dataset_id'] = restored_dataset.id
        #funder.delete('created_at')
        funder.delete('updated_at')
        restored_funder = restored_dataset.funders.build(funder)
        restored_funder.save
        RestorationIdMap.create(restoration_event_id: event_id, id_class: "Funder", old_id: funder_old_id, new_id: restored_funder.id)
      end

      # clear changelog from audits done during restoration
      changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', restored_dataset.id, restored_dataset.id)
      changes.destroy_all

      # restore changelog

      changes_hash_raw = JSON.parse(Dataset.get_changelog_from_medusa(identifier_to_restore))
      change_hash_array = changes_hash_raw['changes']

      Rails.logger.warn "change_hash_array count: #{change_hash_array.count}"

      change_hash_array.each do |change_hash|
        change = change_hash['change']
        agent = change_hash['agent']

        agent_user = nil

        if agent && agent['email']
          agent_user = User::Shibboleth.find_by(email: agent['email'])

          unless agent_user

            agent_user = User::Shibboleth.create(provider: agent['provider'],
                                     uid: agent['uid'],
                                     name: agent['name'],
                                     role: agent['role'],
                                     username: agent['username'])

          end
        else
          agent_user = User::Shibboleth.create(provider: 'recovery',
                                   uid: 'recovery',
                                   name: 'recovery',
                                   role: 'admin',
                                   username: 'recovery')

        end

        agent_id = agent_user.id

        recover_audit_record(change, agent_id, event_id)

      end

      restored_dataset.save
      restored_dataset

    end

  end
end

