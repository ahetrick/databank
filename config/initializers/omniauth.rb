Rails.application.config.middleware.use OmniAuth::Builder do
  #provider :developer unless Rails.env.production?

  idb_config = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

  if idb_config.has_key?(:local_mode) && idb_config[:local_mode]
    provider :identity
  else
    opts = YAML.load_file(File.join(Rails.root, 'config', 'shibboleth.yml'))[Rails.env]
    provider :shibboleth, opts.symbolize_keys
    Databank::Application.shibboleth_host = opts['host']
  end

end