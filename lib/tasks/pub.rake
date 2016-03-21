require 'rake'
namespace :pub do

  desc 'update publication state for datasets with current or past release date'
  task :update_state => :environment do

    @current_user  = User.find_by_provider_and_uid("system", IDB_CONFIG[:system_user_email])

    if !@current_user
      @current_user = User.create_system_user
    end

    Dataset.all.each do |dataset|
      if [Databank::PublicationState::METADATA_EMBARGO, Databank::PublicationState::FILE_EMBARGO].include?(dataset.publication_state) && dataset.release_date <= Date.current()
        dataset.publication_state = Databank::PublicationState::RELEASED
        dataset.embargo = ''
        dataset.save
        if dataset.has_datacite_change
          dataset.update_datacite_metadata(@current_user)
        end
      end
    end
  end

end