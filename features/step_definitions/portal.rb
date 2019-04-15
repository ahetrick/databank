# frozen_string_literal: true

And("I add {string} as an invitee") do |email|
  expect(page).to have_selector("#add-account-btn", visible: true)
  find("#add-account-btn").click
  fill_in("invitee_email", with: email)
  click_button("Add")
end

Given("There is a current invitation for {string}") do |email|
  invitee = Invitee.find_by(email: email) || create(:invitee, email: email)
  expect(invitee.expires_at).to be > Time.current
end

Given("There is no identity for {string}") do |email|
  identities = Identity.where(email: email)
  expect(identities.count).to eq(0)
end

When("I register as {string}") do |email|
  step "I am on the Data Curation Network Portal register page"
  fill_in("name", with: "Example Curator")
  fill_in("email", with: email)
  fill_in("password", with: "password")
  fill_in("password_confirmation", with: "password")
  click_button("Register")
end