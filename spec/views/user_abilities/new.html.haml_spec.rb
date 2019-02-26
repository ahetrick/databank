require 'rails_helper'

RSpec.describe "user_abilities/new", type: :view do
  before(:each) do
    assign(:user_ability, UserAbility.new(
      :dataset_id => 1,
      :user_name => "MyString",
      :user_email => "MyString",
      :ability => "MyString"
    ))
  end

  it "renders new user_ability form" do
    render

    assert_select "form[action=?][method=?]", user_abilities_path, "post" do

      assert_select "input#user_ability_dataset_id[name=?]", "user_ability[dataset_id]"

      assert_select "input#user_ability_user_name[name=?]", "user_ability[user_name]"

      assert_select "input#user_ability_user_email[name=?]", "user_ability[user_email]"

      assert_select "input#user_ability_ability[name=?]", "user_ability[ability]"
    end
  end
end
