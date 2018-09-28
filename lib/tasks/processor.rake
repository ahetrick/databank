require 'rake'
require 'bunny'
require 'json'

namespace :processor do

  desc 'create tasks for datafiles that do not have one'
  task :create_tasks => :environment do
    Datafile.where(task_id: nil).each do |datafile|
      datafile.create_processor_task
    end

  end

  desc 'remove tasks from datafiles'
  task :remove_all_tasks => :environment do
    Datafile.all.each do |datafile|
      datafile.task_id = nil
      datafile.save
    end
  end

end