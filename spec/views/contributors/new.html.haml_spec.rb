require 'rails_helper'

RSpec.describe "contributors/new", type: :view do
  before(:each) do
    assign(:contributor, Contributor.new(
      :dataset_id => 1,
      :family_name => "MyString",
      :given_name => "MyString",
      :institution_name => "MyString",
      :identifier => "MyString",
      :type_of => 1,
      :row_order => 1,
      :email => "MyString",
      :row_position => 1,
      :identifier_scheme => "MyString"
    ))
  end

  it "renders new contributor form" do
    render

    assert_select "form[action=?][method=?]", contributors_path, "post" do

      assert_select "input#contributor_dataset_id[name=?]", "contributor[dataset_id]"

      assert_select "input#contributor_family_name[name=?]", "contributor[family_name]"

      assert_select "input#contributor_given_name[name=?]", "contributor[given_name]"

      assert_select "input#contributor_institution_name[name=?]", "contributor[institution_name]"

      assert_select "input#contributor_identifier[name=?]", "contributor[identifier]"

      assert_select "input#contributor_type_of[name=?]", "contributor[type_of]"

      assert_select "input#contributor_row_order[name=?]", "contributor[row_order]"

      assert_select "input#contributor_email[name=?]", "contributor[email]"

      assert_select "input#contributor_row_position[name=?]", "contributor[row_position]"

      assert_select "input#contributor_identifier_scheme[name=?]", "contributor[identifier_scheme]"
    end
  end
end
