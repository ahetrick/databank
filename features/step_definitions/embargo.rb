When(/^I select release date delay \((\d+)\+ years\)$/) do |num_years|
  fill_in('Release Date', with: Date.current + (num_years.to_i).years)

end

When(/^I select file & metadata publication delay$/) do
  select('File and Metadata Publication Delay', from: 'dataset_embargo')
end

When(/^I select file only publication delay$/) do
  select('File Only Publication Delay', from: 'dataset_embargo')
end

When(/^I select no publication delay$/) do
  select('No Publication Delay', from: 'dataset_embargo')
end

Given(/^I have a published dataset with a file & metadata publication delay$/) do
  @dataset = FactoryGirl.create(:dataset)
  @dataset.save
  step("I visit the dataset edit page")
  step("I fill in required dataset metadata")
  select('File and Metadata Publication Delay', from: 'dataset_embargo')
  fill_in('Release Date', with: Date.current + 1.years)
  step("I attach a file")
  step("I click on 'Continue'")
  step("I click on 'Confirm'")
  step("I click on 'Publish'")
end

When(/^I leave release date field$/) do
  find_field("Release Date").send_keys :tab
end

Then(/^I see an alert "(.+?)"$/) do |content|
  expect(page.driver.browser.switch_to.alert.text).to match(content)
  page.driver.browser.switch_to.alert.accept
end

Then(/^I see the release date set to one year from now$/) do
  expect(find_field("Release Date").value).to match((Date.current + 1.years).to_s)
end

Then(/^I see only No Publication Delay option$/) do
  expect(page).to have_select('dataset_embargo'),
      selected: 'No Publication Delay',
      options: ['No Publication Delay']
end
