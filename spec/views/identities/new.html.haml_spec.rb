require 'rails_helper'

RSpec.describe "identities/new", type: :view do
  before(:each) do
    assign(:identity, Identity.new())
  end

  it "renders new identity form" do
    render

    assert_select "form[action=?][method=?]", identities_path, "post" do
    end
  end
end
