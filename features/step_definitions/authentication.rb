Given("I am not logged in") do
  visit "/logout"
end

Given("I am logged in as an {string}") do |role|
  login_identity({role: role})
end

Given("I am logged in as {string}") do |email|
  login_identity({email: email})
end

private

def login_identity(opts = {})
  localpass = IDB_CONFIG[:admin][:localpass]
  email = opts[:email]
  invitee = Invitee.find_by(email: email) || FactoryBot.create(:invitee, opts)
  identity = Identity.find_by(opts[:email]) || FactoryBot.create(:identity, {email: invitee.email})
  visit("/identities/login")
  fill_in('Email', with: identity.email)
  fill_in('password', with: localpass)
  click_button('Log In')
end