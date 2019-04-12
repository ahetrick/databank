# frozen_string_literal: true

Given "I am not logged in" do
  visit "/logout"
end

When "I log out" do
  visit "/logout"
end

When("I am logged in as an {string}") do |role|
  login_identity_user(role)
end

Given "I relogin as {string}" do |login_type|
  step "I log out"
  step "I am logged in as #{login_type}"
end

Given "I go to the identity log in page" do
  visit "/identities/login"
end

Given "I go to the data_curation_network log in page" do
  visit "/data_curation_network"
end

Then "I am on the identity log in page" do
  expect(current_path).to eql("/identities/login")
end

Then "I am on the data_curation_network log in page" do
  expect(current_path).to eql("/data_curation_network")
end

private

def login_identity_user(role)
  # omniauth identity mock user defined in
  # /config/environments/test.rb
  # Login Manager credentials defined in
  # /features/support/login_data.yml

  visit("/logout")

  email = LoginManager.instance.auth_key(:identity)
  name = LoginManager.instance.name(:identity)
  password = LoginManager.instance.password(:identity)
  invitee = Invitee.create!(email: email,
                            role: role,
                            expires_at: Time.current + 1.month)
  expect(invitee).not_to be_nil
  expect(invitee.email).to eq(email)
  identity = Identity.create!(email: invitee.email,
                              name: name,
                              password: password)
  expect(identity).not_to be_nil
  identity.update_attribute(:activated,    true)
  identity.update_attribute(:activated_at, Time.current - 1.month)
  expect(identity.activated).to be true

  visit("/identities/login")
  fill_in("auth_key", with: email)
  fill_in("password", with: password)
  expect(page).to have_selector("#login", visible: true)
  find("#login").click
end
