class Identity < OmniAuth::Identity::Models::ActiveRecord
  GROUPS = %w[network_curator publisher collaborator]
  STATES = %w[pending active expired]
end
