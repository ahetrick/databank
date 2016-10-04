Then(/^I should see '(.*)'$/) do |text|
  page.should have_content(text)
end

And(/^I should not see '(.*)'$/) do |text|
  page.should_not have_content(text)
end

And /^I should see all of:$/ do |table|
  table.headers.each do |header|
    step "I should see '#{header}'"
  end
end

And /^I should see none of:$/ do |table|
  table.headers.each do |header|
    step "I should not see '#{header}'"
  end
end