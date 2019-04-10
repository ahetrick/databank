Given(/^I am a current admin invitee$/) do
  admin_email = "admin@mailinator.com"
  invitee = Invitee.find_by_email(admin_email)
  invitee = create(:invitee) unless invitee
  invitee.update_attribute(expires_at, Time.now + 1.years)
  invitee.update_attribute(role, Databank::UserRole::ADMIN)
end

Given(/^I have an activated admin identity$/) do
  step 'I am a current inviteee'
  admin_email = "admin@mailinator.com"
  identity = Identity.find_by_email(admin_email)
  identity = create(:identity) unless identity
  identity.update_attribute(activated, true)
end






When(/^I log in$/) do
  #cookie may already exist, in which case visiting hte login path with just log in
  step 'I visit the login page'
  # shibboleth login path if no cookie exists redirects to idp/...
  if current_path.include?('idp')
    fill_in('j_username', with: LoginManager.instance.name(:shibboleth))
    fill_in('j_password', with: LoginManager.instance.password(:shibboleth))
    step "I click on 'Login'"
    # local mode login path if no cookie exists redirects to /auth/idenity
    # creating a user logs in for local mode
  elsif current_path == "/auth/identity"
    click_on('Create')
    fill_in('name', with: 'Test User')
    fill_in('email', with: 'mfall3@mailinator.com')
    fill_in('password', with: 'password')
    fill_in('password_confirmation', with: 'password')
    click_on('Connect')
  end
end

When(/^I log in as a curator$/) do
  #cookie may already exist, in which case visiting hte login path with just log in
  step 'I visit the login page'
  # shibboleth login path if no cookie exists redirects to idp/...
  if current_path.include?('idp')
    fill_in('j_username', with: LoginManager.instance.name(:shibboleth))
    fill_in('j_password', with: LoginManager.instance.password(:shibboleth))
    step "I click on 'Login'"
    # local mode login path if no cookie exists redirects to /auth/idenity
    # creating a user logs in for local mode
  elsif current_path == "/auth/identity"
    click_on('Create')
    fill_in('name', with: 'Test User')
    fill_in('email', with: 'mfall3@mailinator.com')
    fill_in('password', with: 'password')
    fill_in('password_confirmation', with: 'password')
    click_on('Connect')
  end
end

When(/^I log in via shibboleth$/) do
  step 'I visit the login page'
  fill_in('j_username', with: LoginManager.instance.name(:shibboleth))
  fill_in('j_password', with: LoginManager.instance.password(:shibboleth))
  step "I click on 'Login'"
end

LOGGED_IN_LINKS = ['Log out']

Then(/^I see logged in links$/) do
  LOGGED_IN_LINKS.each do |text|
    expect(page).to have_content(text)
  end
end

Then(/^I do not see logged in links$/) do
  LOGGED_IN_LINKS.each do |text|
    expect(page).to have_no_content(text)
  end
end

Then(/^I see switch to depositor confirmation message$/) do
  expect(page).to have_content("Successfully switched role to depositor")
end

Then(/^I see switch to undergrad confirmation message$/) do
  expect(page).to have_content("Successfully switched role to undergrad")
end

And(/^I switch role to depositor$/) do
  select('depositor', :from=>'role')
  step "I click on 'Switch'"
end

And(/^I switch role to undergrad$/) do
  select('undergrad', :from=>'role')
  step "I click on 'Switch'"
end

When(/^I log out$/) do
  within(:css, 'div#navbar') do
    click_on('Log out')
  end
end

Given(/^I am logged out$/) do
  step"I visit the logout page"
end