require 'rails_helper'

RSpec.describe "user_abilities/index", type: :view do
  before(:each) do
    assign(:user_abilities, [
      UserAbility.create!(
        :dataset_id => 2,
        :user_name => "User Name",
        :user_email => "User Email",
        :ability => "Ability"
      ),
      UserAbility.create!(
        :dataset_id => 2,
        :user_name => "User Name",
        :user_email => "User Email",
        :ability => "Ability"
      )
    ])
  end

  it "renders a list of user_abilities" do
    render
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "User Name".to_s, :count => 2
    assert_select "tr>td", :text => "User Email".to_s, :count => 2
    assert_select "tr>td", :text => "Ability".to_s, :count => 2
  end
end
