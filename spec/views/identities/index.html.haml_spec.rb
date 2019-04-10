require 'rails_helper'

RSpec.describe "identities/index", type: :view do
  before(:each) do
    assign(:identities, [
      Identity.create!(),
      Identity.create!()
    ])
  end

  it "renders a list of identities" do
    render
  end
end
