require 'rails_helper'

RSpec.describe "invitees/new", type: :view do
  before(:each) do
    assign(:invitee, Invitee.new())
  end

  it "renders new invitee form" do
    render

    assert_select "form[action=?][method=?]", invitees_path, "post" do
    end
  end
end
