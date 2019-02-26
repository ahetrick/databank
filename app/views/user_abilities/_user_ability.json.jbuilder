json.extract! user_ability, :id, :dataset_id, :user_name, :user_email, :ability, :created_at, :updated_at
json.url user_ability_url(user_ability, format: :json)
