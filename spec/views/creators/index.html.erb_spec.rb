require 'rails_helper'

RSpec.describe "creators/index", :type => :view do
  before(:each) do
    assign(:creators, [
      Creator.create!(
        :dataset_id => 1,
        :family_name => "Family Name",
        :given_name => "Given Name",
        :institution_name => "Institution Name",
        :identifier => "Identifier",
        :type => "Type",
        :position => 2
      ),
      Creator.create!(
        :dataset_id => 1,
        :family_name => "Family Name",
        :given_name => "Given Name",
        :institution_name => "Institution Name",
        :identifier => "Identifier",
        :type => "Type",
        :position => 2
      )
    ])
  end

  it "renders a list of creators" do
    render
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Family Name".to_s, :count => 2
    assert_select "tr>td", :text => "Given Name".to_s, :count => 2
    assert_select "tr>td", :text => "Institution Name".to_s, :count => 2
    assert_select "tr>td", :text => "Identifier".to_s, :count => 2
    assert_select "tr>td", :text => "Type".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
  end
end
