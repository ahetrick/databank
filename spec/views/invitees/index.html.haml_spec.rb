require 'rails_helper'

RSpec.describe "invitees/index", type: :view do
  before(:each) do
    assign(:invitees, [
      Invitee.create!(),
      Invitee.create!()
    ])
  end

  it "renders a list of invitees" do
    render
  end
end
