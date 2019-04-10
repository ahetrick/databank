require 'rails_helper'

RSpec.describe "identities/edit", type: :view do
  before(:each) do
    @identity = assign(:identity, Identity.create!())
  end

  it "renders the edit identity form" do
    render

    assert_select "form[action=?][method=?]", identity_path(@identity), "post" do
    end
  end
end
