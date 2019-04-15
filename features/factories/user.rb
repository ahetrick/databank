# frozen_string_literal: true

FactoryBot.define do
  factory :invitee do
    sequence(:email) {|n| "user#{n}@example.com" }
    role { "admin" }
    expires_at { Date.current + 1.month }
  end
  factory :identity do
    sequence(:name) {|n| "User #{n}" }
    sequence(:email) {|n| "user#{n}@example.com" }
    sequence(:password) {|n| "password#{n}" }
    activated { true }
    activated_at { Time.current - 1.month }
  end
  factory :identity_user, class: User::Identity do
    sequence(:uid) {|n| "user-#{n}" }
    sequence(:name) {|n| "User #{n}" }
    sequence(:email) {|n| "user#{n}@example.com" }
    role { "admin" }
  end
end
