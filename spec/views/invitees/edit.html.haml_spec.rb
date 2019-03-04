require 'rails_helper'

RSpec.describe "invitees/edit", type: :view do
  before(:each) do
    @invitee = assign(:invitee, Invitee.create!())
  end

  it "renders the edit invitee form" do
    render

    assert_select "form[action=?][method=?]", invitee_path(@invitee), "post" do
    end
  end
end
