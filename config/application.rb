require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.

require 'selenium-webdriver'
Bundler.require(*Rails.groups)

module Databank

  # file means all files only
  # metadata means all files + metadata
  # TempSuppress states should be able to stack with other states
  # Most restrictive state is effective

  class PublicationState
    DRAFT = 'draft'
    RELEASED = 'released'
    class Embargo
      NONE = 'none'
      FILE = 'file embargo'
      METADATA = 'metadata embargo'
    end
    class TempSuppress
      NONE = 'none'
      FILE = 'files temporarily suppressed'
      METADATA = 'metadata temporarily suppressed'
    end
    class PermSuppress
      FILE = 'files permanently suppressed'
      METADATA = 'metadata permanently suppressed'
    end
  end

  class FileMode
    WRITE_READ = 'rw'
    READ_ONLY = 'ro'
  end

  class Relationship
    SUPPLEMENT_TO = 'IsSupplementTo'
    SUPPLEMENTED_BY = 'IsSupplementedBy'
    CITED_BY = 'IsCitedBy'
    PREVIOUS_VERSION_OF = 'IsPreviousVersionOf'
    NEW_VERSION_OF = 'IsNewVersionOf'
  end

  class MaterialType
    ARTICLE = 'Article'
    CODE = 'Code'
    DATASET = 'Dataset'
    PRESENTATION = 'Presentation'
    THESIS = 'Thesis'
    OTHER = 'Other'
  end

  class Subject
    NONE = ''
    PHYSICAL_SCIENCES = 'Physical Sciences'
    LIFE_SCIENCES = 'Life Sciences'
    SOCIAL_SCIENCES = 'Social Sciences'
    TECHNOLOGY_ENGINEERING = 'Technology and Engineering'
    ARTS_HUMANITIES = 'Arts and Humanities'
  end

  class Application < Rails::Application

    attr_accessor :shibboleth_host

    attr_accessor :file_mode

    attr_accessor :settings


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.autoload_paths << File.join(Rails.root, 'helpers/admin')
    config.autoload_paths << File.join(Rails.root, 'jobs')
    config.autoload_paths << File.join(Rails.root, 'lib')
    config.autoload_once_paths << File.join(Rails.root, 'app/models')
    config.autoload_once_paths << File.join(Rails.root, 'app/models/concerns')
    config.active_job.queue_adapter = :delayed_job

  end
end
