# frozen_string_literal: true

Given("I add an invitee") do
  expect(page).to have_selector("#add-account-btn", visible: true)
  find("#add-account-btn").click
  fill_in("invitee_email", with: "portal@example.com")
  pending
end

Then("The invitee can register") do
  pending # Write code here that turns the phrase above into concrete actions
end