require 'rails_helper'

RSpec.describe "datasets/show", :type => :view do
  before(:each) do

    auth = OmniAuth.config.mock_auth[:identity]
    user = User.create_with_omniauth(auth)
    allow(controller).to receive_message_chain(:current_user).and_return(User.find(user.id) )
    @dataset = assign(:dataset, Dataset.create!(
      :title => "Title",
      :identifier => "Identifier",
      :publisher => "Publisher",
      :publication_year => "Publication Year",
      :creator_ordered_ids => "Creator Ordered Ids",
      :license => "License",
      :key => "Key",
      :description => "Description",
      :creator_text => "Creator Text",
      :depositor_name => "Depositor Name",
      :depositor_email => "demo1@example.edu",
      :complete => true,
      :corresponding_creator_name => "Corresponding Creator Name",
      :corresponding_creator_email => "Corresponding Creator Email",
      :binaries_attributes =>{"0"=>{:description=>"placeholder"}}
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Identifier/)
    expect(rendered).to match(/Publisher/)
    expect(rendered).to match(/Publication Year/)
    expect(rendered).to match(/License/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Creator Text/)
    expect(rendered).to match(/Corresponding Creator Name/)
  end
end
