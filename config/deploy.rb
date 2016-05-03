# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'databank'
set :repo_url, 'https://github.com/medusa-project/databank.git'
set :rvm_ruby_version, '2.2.1@idb_v1'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/databank'

set :unicorn_pid, '/home/databank/current/tmp/pids/unicorn.pid'
set :unicorn_config_path, '/home/databank/current/config/unicorn.rb'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml', 'config/databank.yml', 'config/shibboleth.yml', 'config/unicorn.rb', 'public/robots.txt', 'idb_stop.sh', 'idb_start.sh', 'idb_restart.sh', 'dj_stop.sh', 'dj_start.sh')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'scripts', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'tmp/uploads', 'tmp/sessions', 'public/sitemaps')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5


# Defaults to false
# Skip migration if files in db/migrate were not modified
set :conditionally_migrate, true

# Defaults to [:web]
set :assets_roles, [:web, :app]

# Defaults to 'assets'
# This should match config.assets.prefix in your rails config/application.rb

# Defaults to nil (no asset cleanup is performed)
# If you use Rails 4+ and you'd like to clean up old assets after each deploy,
# set this to the number of versions to keep
set :keep_assets, 2

namespace :deploy do

  after 'deploy:publishing', 'deploy:restart'
  namespace :deploy do
    task :restart do
      invoke 'unicorn:restart'
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # within "/home/databank/current" do
      #   execute "pwd"
      #   execute "whoami"
      # end
    end
  end

end
