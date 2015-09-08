FactoryGirl.define do
  factory :identity do
    name "MyString"
    email "MyString"
    salt = BCrypt::Engine.generate_salt
    encrypted_password = BCrypt::Engine.hash_secret("MyString", salt)
    password_digest encrypted_password
  end

end
