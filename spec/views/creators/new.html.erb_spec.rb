require 'rails_helper'

RSpec.describe "creators/new", :type => :view do
  before(:each) do
    assign(:creator, Creator.new(
      :dataset_id => 1,
      :family_name => "MyString",
      :given_name => "MyString",
      :institution_name => "MyString",
      :identifier => "MyString",
      :type => "",
      :position => 1
    ))
  end

  it "renders new creator form" do
    render

    assert_select "form[action=?][method=?]", creators_path, "post" do

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
