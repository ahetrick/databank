require 'rails_helper'

RSpec.describe "contributors/show", type: :view do
  before(:each) do
    @contributor = assign(:contributor, Contributor.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Family Name/)
    expect(rendered).to match(/Given Name/)
    expect(rendered).to match(/Institution Name/)
    expect(rendered).to match(/Identifier/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/Identifier Scheme/)
  end
end
