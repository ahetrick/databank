require 'rails_helper'

RSpec.describe "creators/show", :type => :view do
  before(:each) do
    @creator = assign(:creator, Creator.create!(
      :dataset_id => 1,
      :family_name => "Family Name",
      :given_name => "Given Name",
      :institution_name => "Institution Name",
      :identifier => "Identifier",
      :type => "Type",
      :position => 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/1/)
    expect(rendered).to match(/Family Name/)
    expect(rendered).to match(/Given Name/)
    expect(rendered).to match(/Institution Name/)
    expect(rendered).to match(/Identifier/)
    expect(rendered).to match(/Type/)
    expect(rendered).to match(/2/)
  end
end
