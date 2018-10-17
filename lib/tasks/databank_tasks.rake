require 'rake'
require 'bunny'
require 'json'

include Databank

namespace :databank_tasks do

  desc 'create tasks for datafiles that do not have one'
  task :create_tasks => :environment do
    Datafile.where(task_id: nil).each do |datafile|
      datafile.initiate_processing_task
    end

  end

  desc 'remove tasks from datafiles'
  task :remove_all_tasks => :environment do
    Datafile.all.each do |datafile|
      datafile.task_id = nil
      datafile.save
    end
  end

  desc 'reset test datafile'
  task :reset_test_datafile => :environment do
    datafile = Datafile.find_by_web_id('4ybb9')
    raise RecordNotFound unless datafile

    datafile.task_id = nil
    datafile.peek_type = nil
    datafile.peek_text = nil
    datafile.save

  end

  desc 'import nested items and peek info from complete tasks'
  task :handle_ripe_tasks => :environment do
    Datafile.all.each do |datafile|
      if datafile&.task_id
        task_hash = DatabankTask.get_remote_task(datafile.task_id)

        if task_hash.has_key?('status') && task_hash['status'] == TaskStatus::RIPE

          # claim tasks
          DatabankTask.set_remote_task_status(datafile.task_id, TaskStatus::HARVESTING)

          Rails.logger.warn(task_hash)

          if task_hash.has_key?('peek_type') && task_hash['peek_text'] != nil
            Rails.logger.warn("inside non-nil peek_type")
            Rails.logger.warn("task_hash['peek_type'] #{task_hash['peek_type']}")
            datafile.peek_type = task_hash['peek_type']
            Rails.logger.warn("datafile.peek_type #{datafile.peek_type}")
          else
            Rails.logger.warn("no peek_type key or nil value")
            datafile.peek_type = PeekType::NONE
          end

          if task_hash.has_key?('peek_text') && task_hash['peek_text'] != nil
            datafile.peek_text = task_hash['peek_text'].encode('utf-8')
          else
            datafile.peek_text = ""
          end

          datafile.save

          if datafile.peek_type == PeekType::LISTING

            remote_nested_items = DatabankTask.get_remote_items(datafile.task_id)
            remote_nested_items.each do |item|

              existing_items = NestedItem.where(datafile_id: datafile.id, item_path: item['item_path'])

              if existing_items.count > 0
                existing_items.each do |exising_item|
                  exising_item.destroy
                end
              end

              NestedItem.create(datafile_id: datafile.id,
                                item_name: item['item_name'],
                                item_path: item['item_path'],
                                media_type: item['media_type'],
                                size: item['item_size'],
                                is_directory: item['is_directory'] == "true" )
            end

          end

          # close tasks
          DatabankTask.set_remote_task_status(datafile.task_id, TaskStatus::HARVESTED)

        end

      end

    end
  end

  desc 'reset test harvesting tasks back to ripe'
  task :set_ripe => :environment do
    Datafile.all.each do |datafile|
      if datafile && datafile.task_id
        task_hash = DatabankTask.get_remote_task(datafile.task_id)
        if task_hash.has_key?('status') && task_hash['status'] == TaskStatus::HARVESTING
          DatabankTask.set_remote_task_status(datafile.task_id, TaskStatus::RIPE)
        end

      end

    end
  end

end