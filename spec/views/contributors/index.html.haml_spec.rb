require 'rails_helper'

RSpec.describe "contributors/index", type: :view do
  before(:each) do
    assign(:contributors, [
      Contributor.create!(
        :dataset_id => 2,
        :family_name => "Family Name",
        :given_name => "Given Name",
        :institution_name => "Institution Name",
        :identifier => "Identifier",
        :type_of => 3,
        :row_order => 4,
        :email => "Email",
        :row_position => 5,
        :identifier_scheme => "Identifier Scheme"
      ),
      Contributor.create!(
        :dataset_id => 2,
        :family_name => "Family Name",
        :given_name => "Given Name",
        :institution_name => "Institution Name",
        :identifier => "Identifier",
        :type_of => 3,
        :row_order => 4,
        :email => "Email",
        :row_position => 5,
        :identifier_scheme => "Identifier Scheme"
      )
    ])
  end

  it "renders a list of contributors" do
    render
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Family Name".to_s, :count => 2
    assert_select "tr>td", :text => "Given Name".to_s, :count => 2
    assert_select "tr>td", :text => "Institution Name".to_s, :count => 2
    assert_select "tr>td", :text => "Identifier".to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => 4.to_s, :count => 2
    assert_select "tr>td", :text => "Email".to_s, :count => 2
    assert_select "tr>td", :text => 5.to_s, :count => 2
    assert_select "tr>td", :text => "Identifier Scheme".to_s, :count => 2
  end
end
