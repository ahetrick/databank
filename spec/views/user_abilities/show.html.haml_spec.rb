require 'rails_helper'

RSpec.describe "user_abilities/show", type: :view do
  before(:each) do
    @user_ability = assign(:user_ability, UserAbility.create!(
      :dataset_id => 2,
      :user_name => "User Name",
      :user_email => "User Email",
      :ability => "Ability"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/2/)
    expect(rendered).to match(/User Name/)
    expect(rendered).to match(/User Email/)
    expect(rendered).to match(/Ability/)
  end
end
