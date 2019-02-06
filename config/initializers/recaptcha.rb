# config/initializers/recaptcha.rb
Recaptcha.configure do |config|
  config.site_key  = IDB_CONFIG[:recaptcha][:site_key]
  config.secret_key = IDB_CONFIG[:recaptcha][:secret_key]
  # Uncomment the following line if you are using a proxy server:
  if IDB_CONFIG[:local_mode] != true
    config.proxy = 'http://databank.illinois.edu'
  end
end