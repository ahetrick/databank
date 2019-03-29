require 'rails_helper'

RSpec.describe "invitees/show", type: :view do
  before(:each) do
    @invitee = assign(:invitee, Invitee.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
