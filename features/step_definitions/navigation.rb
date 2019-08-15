When("I go to the site home") do
  visit '/'
end

When("I click on {string} in the global navigation bar") do |name|
  within('#global-navigation') {click_link name}
end

When("I should be on the site home page") do
  current_path.should == root_path
end
