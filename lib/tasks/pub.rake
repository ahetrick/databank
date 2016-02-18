require 'rake'
namespace :pub do

  desc 'update publication state for datasets with current or past release date'
  task :update_state => :environment do
    Dataset.all.each do |dataset|
      if [Databank::PublicationState::METADATA_EMBARGO, Databank::PublicationState::FILE_EMBARGO].include?(dataset.publication_state) && dataset.release_date <= Date.current()
        dataset.publication_state = Databank::PublicationState::RELEASED
        dataset.embargo = ''
        dataset.save
      end
    end
  end

end