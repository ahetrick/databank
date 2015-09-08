require 'rails_helper'

RSpec.describe "datasets/index", :type => :view do
  before(:each) do
    auth = OmniAuth.config.mock_auth[:identity]
    user = User.create_with_omniauth(auth)
    allow(controller).to receive_message_chain(:current_user).and_return(User.find(user.id) )

    assign(:datasets, [
      Dataset.create!(
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
        :depositor_email => "Depositor Email",
        :complete => true,
        :corresponding_creator_name => "Corresponding Creator Name",
        :corresponding_creator_email => "Corresponding Creator Email",
        :binaries_attributes =>{"0"=>{:description=>"placeholder"}}
      ),
      Dataset.create!(
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
        :depositor_email => "Depositor Email",
        :complete => true,
        :corresponding_creator_name => "Corresponding Creator Name",
        :corresponding_creator_email => "Corresponding Creator Email",
        :binaries_attributes =>{"0"=>{:description=>"placeholder"}}
      )
    ])
  end

  it "renders a list of datasets" do
    render
    assert_select ":match('href', ?)", :count => 2

  end
end
