require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Databank

  NAMESPACE_URI = 'http://databank.illinois.edu/definitions/v1#'

  ##
  # "System objects" used by the application in the subject-predicate-object
  # sense. These will be appended to NAMESPACE_URI.
  #
  class RDFObjects
    DERIVATIVE_BYTESTREAM = 'Bytestream/Type/Derivative'
    MASTER_BYTESTREAM = 'Bytestream/Type/Master'
    ORIGINAL_SHAPE = 'Bytestream/Shape/Original'
    SQUARE_SHAPE = 'Bytestream/Shape/Square'
    BYTESTREAM = 'Bytestream'
    DATAFILE = 'Datafile'
    DATASET = 'Dataset'
  end

  ##
  # "System predicates" used by the application in the
  # subject-predicate-object sense. These will be appended to NAMESPACE_URI.
  #
  class RDFPredicates

    BYTE_SIZE = 'byteSize'
    BYTESTREAM_SHAPE = 'bytestreamShape'
    BYTESTREAM_TYPE = 'bytestreamType'
    BYTESTREAM_URI = 'hasBytestream'
    CLASS = 'hasClass'
    DATASET_KEY = 'datasetKey'
    DATE = 'date'
    FULL_TEXT = 'fullText'
    HEIGHT = 'height'
    IS_MEMBER_OF_DATASET = 'isMemberOfDataset'
    IS_MEMBER_OF_DATAFILE = 'isMemberOfDatafile'
    PAGE_INDEX = 'pageIndex'
    PARENT_URI = 'hasParent'
    PUBLISHED = 'published'
    WEB_ID = 'webID'
    WIDTH = 'width'

  end

  class Application < Rails::Application

    attr_accessor :shibboleth_host

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
