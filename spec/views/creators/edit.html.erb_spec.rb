require 'rails_helper'

RSpec.describe "creators/edit", :type => :view do
  before(:each) do
    @creator = assign(:creator, Creator.create!(
      :dataset_id => 1,
      :family_name => "MyString",
      :given_name => "MyString",
      :institution_name => "MyString",
      :identifier => "MyString",
      :type => "",
      :position => 1
    ))
  end

  it "renders the edit creator form" do
    render

    assert_select "form[action=?][method=?]", creator_path(@creator), "post" do

      assert_select "input#creator_dataset_id[name=?]", "creator[dataset_id]"

      assert_select "input#creator_family_name[name=?]", "creator[family_name]"

      assert_select "input#creator_given_name[name=?]", "creator[given_name]"

      assert_select "input#creator_institution_name[name=?]", "creator[institution_name]"

      assert_select "input#creator_identifier[name=?]", "creator[identifier]"

      assert_select "input#creator_type[name=?]", "creator[type]"

      assert_select "input#creator_position[name=?]", "creator[position]"
    end
  end
end
