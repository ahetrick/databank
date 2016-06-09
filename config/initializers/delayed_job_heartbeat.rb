Delayed::Heartbeat.configure do |configuration|
  configuration.enabled = true
  configuration.heartbeat_interval_seconds = 60
  configuration.heartbeat_timeout_seconds = 180
  configuration.worker_termination_enabled = true
end