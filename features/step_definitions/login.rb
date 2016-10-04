When(/^I log in via shibboleth$/) do
  step 'I visit the login page'
  fill_in('j_username', with: LoginManager.instance.name(:shibboleth))
  fill_in('j_password', with: LoginManager.instance.password(:shibboleth))
  step "I click on 'Login'"
end

LOGGED_IN_LINKS = ['Log out']

Then(/^I should see logged in links$/) do
  LOGGED_IN_LINKS.each do |text|
    page.should have_content(text)
  end
end

Then(/^I should not see logged in links$/) do
  within('#ds-user-box') do
    LOGGED_IN_LINKS.each do |text|
      page.should_not have_content(text)
    end
  end
end

When(/^I log out$/) do
  within('#aspect_viewArtifacts_Navigation_list_account') do
    click_link('Log out')
  end
end
