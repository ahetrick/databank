When(/^I visit the login page$/) do
  visit '/login'
end

When(/^I visit the logout page$/) do
  visit '/logout'
end

When(/^I visit the help page$/) do
  visit '/help'
end

When(/^I visit the policies page$/) do
  visit '/policies'
end

When(/^I visit the find page$/) do
  visit '/datasets'
end

And(/^I click the help link$/) do
  within('#navbar') do
    click_on('Help')
  end
end

And(/^I click the policies link$/) do
  within('#navbar') do
    click_on('Policies')
  end
end

When(/^I click Deposit Dataset from the navbar$/) do
  within('#navbar') do
    click_on('Deposit Dataset')
  end
end

When(/^I visit the dataset page$/) do
  visit "/datasets/#{@dataset.key}"
end

When(/^I visit the dataset edit page$/) do
  visit "/datasets/#{@dataset.key}/edit"
end

When(/^I maximize the browser$/) do
  @driver.manage.window.maximize
end

