json.array!(@admin) do |admin|
  json.extract! admin, :id, :read_only_alert, :singleton_guard
  json.url admin_url(admin, format: :json)
end
