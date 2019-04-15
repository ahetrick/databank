# frozen_string_literal: true

Given "I am not logged in" do
  visit "/logout"
end

When "I log out" do
  visit "/logout"
end

When("I am logged in as {string}") do |role|
  login_identity_user(role)
end

Given "I relogin as {string}" do |role|
  step "I log out"
  step "I am logged in as #{role}"
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

  step "I am not logged in"

  invitee = create(:invitee, expires_at: Time.current + 1.month, role: role)
  identity = create(:identity, email: invitee.email, name:"#{role.capitalize} User")
  expect(identity.activated).to be true
  visit("/identities/login")
  fill_in("auth_key", with: identity.email)
  fill_in("password", with: identity.password)
  expect(page).to have_selector("#login", visible: true)
  find("#login").click
end
