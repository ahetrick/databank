And "I go to the site home" do
  visit '/'
end

Then "I am on the site home page" do
  expect(current_path).to eql(root_path)
end

When("I click on {string} from the navbar") do |button_label|
  within('#navbar') do
    click_on(button_label)
  end
end

When("I click on {string} element") do |element|
  click_on(element)
end

Then("I see {string} on the page") do |string|
  expect(page).to have_content(string)
end