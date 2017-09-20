require 'yaml'

class FeaturedResearcher < ActiveRecord::Base
  def set_as_featured_researcher

    featured_config = {}
    yaml_filename = File.join(Rails.root, 'config', 'featured_researcher.yml')
    if File.exists?(yaml_filename)
      featured_config = YAML::load_file(yaml_filename)
    end
    featured_config[:featured_researcher_id] = self.id
    File.open(yaml_filename, 'w') {|f| f.write featured_config.to_yaml}
  end

  def self.get_featured_researcher

    yaml_filename = File.join(Rails.root, 'config', 'featured_researcher.yml')

    if File.exists?(yaml_filename)

      featured_config = YAML::load_file(yaml_filename) || {}
      if featured_config.has_key?(:featured_researcher_id)
        featured_researcher = FeaturedResearcher.find(featured_config[:featured_researcher_id])
        if featured_researcher
          return featured_researcher
        else
          return nil
        end
      else
        return nil
      end
    else
      return nil
    end
  end


end
