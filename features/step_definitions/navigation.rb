# frozen_string_literal: true

And "I go to the site home" do
  visit "/"
end

Then "I am on the site home page" do
  expect(current_path).to eql(root_path)
end

When("I click on {string} from the navbar") do |button_label|
  within("#navbar") do
    click_on(button_label)
  end
end

Given("I go to the data curation network portal home") do
  visit "/data_curation_network"
end

Given("I go to the Data Curation Network Portal accounts page") do
  visit "/data_curation_network/accounts"
end

Then("I am on the Data Curation Network Portal accounts page") do
  expect(current_path).to eql("/data_curation_network/accounts")
end

Then("I am on Data Curation Network account add page") do
  expect(current_path).to eql("/data_curation_network/account/add")
end

When("I go to the Data Curation Network Portal register page") do
  visit("/data_curation_network/register")
end

Then("I am on the Data Curation Network Portal register page") do
  expect(current_path).to eql("/data_curation_network/register")
end

When("I go to the Illinois Experts xml page") do
  visit("/illinois_experts.xml")
end

Then("I am on the Illinois Experts xml page") do
  expect(current_path).to eql("/illinois_experts.xml")
end


When("I click on {string} button") do |button_label|
  click_on(button_label)
end

Then("I see {string} on the page") do |string|
  expect(page).to have_content(string)
end

