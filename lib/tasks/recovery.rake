require 'rake'
require 'json'

namespace :recovery do

  desc 'confirm_backup'
  task :confirm_backup => :environment do

    notification = DatabankMailer.backup_report()
    notification.deliver_now

  end

end