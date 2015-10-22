IDB_CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]
# jQuery fileupload iframe-transport needs this:
Rails.application.config.middleware.use JQuery::FileUpload::Rails::Middleware