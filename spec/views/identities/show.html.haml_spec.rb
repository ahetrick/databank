require 'rails_helper'

RSpec.describe "identities/show", type: :view do
  before(:each) do
    @identity = assign(:identity, Identity.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
