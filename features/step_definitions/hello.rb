When(/^I visit the home page$/) do
  visit root_path
end

When(/^I pause for (\d+) seconds$/) do |num_seconds|
  sleep(inspection_time=num_seconds.to_i)
end
