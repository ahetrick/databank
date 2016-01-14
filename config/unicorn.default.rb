listen 3000, :tcp_nopush => false
# set path to application
app_path = "/home/databank"
working_directory "#{app_path}/current"

# Set unicorn options
worker_processes 4
preload_app true
timeout 30

# Set up socket location
listen  ("#{app_path}/shared/tmp/sockets/unicorn.databank.sock"), :backlog => 64

# Logging
stderr_path "#{app_path}/current/log/unicorn.stderr.log"
stdout_path "#{app_path}/current/log/unicorn.stdout.log"

# Set master PID location
pid "#{app_path}/current/tmp/pids/unicorn.pid"

# use correct Gemfile on restarts
before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{app_path}/current/Gemfile"
end

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end
end