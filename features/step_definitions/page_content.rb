Then(/^I see '(.*)'$/) do |text|
  expect(page).to have_content(text)
end

And(/^I do not see '(.*)'$/) do |text|
  expect(page).to have_no_content(text)
end

And /^I see all of:$/ do |table|
  table.headers.each do |header|
    step "I see '#{header}'"
  end
end

And /^I see none of:$/ do |table|
  table.headers.each do |header|
    step "I do not see '#{header}'"
  end
end