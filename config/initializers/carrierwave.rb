CarrierWave.configure do |config|
  # These permissions will make dir and files available only to the user running
  # the servers
  config.permissions = 0600
  config.directory_permissions = 0700
  config.storage = :file

end