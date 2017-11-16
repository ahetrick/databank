# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.

server 'databank-pilot.library.illinois.edu', user: 'centos', roles: %w{app db web}

set :rails_env, 'production'

set :ssh_options, {
    forward_agent: true,
    auth_methods: ["publickey"],
    keys: ["#{Dir.home}/.ssh/medusa-pilot.pem"]
}

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/centos'
