Rails.application.config.middleware.use OmniAuth::Builder do
  #provider :developer unless Rails.env.production?
  provider :identity
  # opts = YAML.load_file(File.join(Rails.root, 'config', 'shibboleth.yml'))[Rails.env]
  # provider :shibboleth, opts.symbolize_keys
  # shibboleth_host = opts['host']
end