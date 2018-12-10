require 'rake'
require 'bunny'
require 'json'
require 'mime/types'

include Databank

namespace :databank_tasks do

  desc 'remove tasks from datafiles'
  task :remove_all_tasks => :environment do
    Datafile.all.each do |datafile|
      datafile.task_id = nil
      datafile.save
    end
  end

  desc 'set missing peek_info from mime_type and size'
  task :set_missing_peek_info => :environment do

    datafiles = Datafile.where(peek_type: nil)

    datafiles.each do |datafile|
      #puts "processing #{datafile.binary_name}"
      if !datafile.mime_type || datafile.mime_type == ''
        mime_guesses_set = MIME::Types.type_for(datafile.binary_name.downcase)
        if mime_guesses_set && mime_guesses_set.length > 0
          datafile.mime_type = mime_guesses_set[0].content_type
        else
          datafile.mime_type = 'application/octet-stream'
        end

      end

      initial_peek_type = Datafile.peek_type_from_mime(datafile.mime_type, datafile.binary_size)

      #puts initial_peek_type
      if initial_peek_type
        datafile.peek_type = initial_peek_type
        if initial_peek_type == Databank::PeekType::ALL_TEXT
          all_text_peek = datafile.get_all_text_peek
          if all_text_peek
            datafile.peek_text = datafile.get_all_text_peek
          else
            datafile.peek_type = Databank::PeekType::NONE
            datafile.peek_text = nil
          end

        elsif initial_peek_type == Databank::PeekType::PART_TEXT
          part_text_peek = datafile.get_part_text_peek
          if part_text_peek
            datafile.peek_text = datafile.get_part_text_peek
          else
            datafile.peek_type = Databank::PeekType::NONE
            datafile.peek_text = nil
          end
        elsif initial_peek_type == Databank::PeekType::MICROSOFT
          datafile.peek_type = initial_peek_type
        elsif initial_peek_type == Databank::PeekType::PDF
          datafile.peek_type = initial_peek_type
        elsif initial_peek_type == Databank::PeekType::IMAGE
          datafile.peek_type = initial_peek_type

        elsif initial_peek_type == Databank::PeekType::LISTING
          datafile.peek_type = Databank::PeekType::NONE
          datafile.initiate_processing_task
        end
      else
        datafile.peek_type = Databank::PeekType::NONE
      end

      begin
        datafile.save
      rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError, ArgumentError
        datafile.peek_type = Databank::PeekType::NONE
        datafile.peek_text = nil
        datafile.save
      end


    end

  end

  desc 'import nested items and peek info from complete tasks'
  task :handle_ripe_tasks => :environment do
    Datafile.all.each do |datafile|
      if datafile&.task_id
        task_hash = DatabankTask.get_remote_task(datafile.task_id)

        if task_hash.has_key?('status') && task_hash['status'] == TaskStatus::RIPE

          # claim tasks
          DatabankTask.set_remote_task_status(datafile.task_id, TaskStatus::HARVESTING)

          if task_hash.has_key?('peek_type')
            datafile.peek_type = task_hash['peek_type']
          else
            datafile.peek_type = Databank::PeekType::NONE
          end

          if task_hash.has_key?('peek_text') && task_hash['peek_text'] != nil
            datafile.peek_text = task_hash['peek_text'].encode('utf-8')
          else
            datafile.peek_text = ""
          end

          datafile.save

          if datafile.peek_type == Databank::PeekType::LISTING

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