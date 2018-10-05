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

  desc 'import nested items and peek info from complete tasks'
  task :handle_completed_tasks => :environment do
    Datafile.all.each do |datafile|
      if datafile && datafile.task_id
        task_hash = DatabankTask.get_remote_task(datafile.task_id)

        if task_hash.has_key?('status') && task_hash['status'] == TaskStatus::RIPE

          # claim tasks
          DatabankTask.set_remote_task_status(datafile.task_id, TaskStatus::HARVESTING)

          if task_hash.has_key?('peek_type')
            datafile.peek_type = item['peek_type']
          end

          if task_hash.has_key?('peek_text')
            datafile.peek_text = item['peek_text'].encode('utf-8')
          end

          datafile.save

          remote_nested_items = DatabankTask.get_remote_items(datafile.task_id)
          remote_nested_items.each do |item|

            NestedItem.create(datafile_id: datafile.id,
                              item_name: item['item_name'],
                              item_path: item['item_path'],
                              media_type: item['media_type'],
                              size: item['item_size'],
                              is_directory: item['is_directory'] )
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