FactoryBot.define do

  factory :invitee do
    email { 'testy@mailinator.com' }
    role { Databank::UserRole::ADMIN }
    expires_at { Time.now + 1.years }
  end

  factory :identity do
    email { 'testy@mailinator.com' }
    password_digest { 'password' }
    name {'Testy Tester'}
    activated { true }
  end

  factory :user do
    provider { 'identity' }
    uid { 'testy@mailinator.com' }
    name { 'Testy Tester' }
    role { Databank::UserRole::ADMIN }
    username { 'testy@mailinator.com' }
  end

end