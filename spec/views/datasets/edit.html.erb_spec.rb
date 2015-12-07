require 'rails_helper'

RSpec.describe "datasets/edit", :type => :view do
  before(:each) do
    auth = OmniAuth.config.mock_auth[:identity]
    user = User.create_with_omniauth(auth)
    allow(controller).to receive_message_chain(:current_user).and_return(User.find(user.id) )

    @dataset = assign(:dataset, Dataset.create!(
      :title => "MyString",
      :identifier => "MyString",
      :publisher => "University of Illinois at Urbana-Champaign",
      :publication_year => "MyString",
      :creator_ordered_ids => "MyString",
      :license => "MyString",
      :key => "MyString",
      :description => "MyString",
      :creator_text => "MyString",
      :depositor_name => "MyString",
      :depositor_email => "demo1@example.edu",
      :complete => true,
      :corresponding_creator_name => "MyString",
      :corresponding_creator_email => "MyString",
      :binaries_attributes =>{"0"=>{:description=>"placeholder"}}

    ))
  end

  it "renders the edit dataset form" do

    render

    assert_select "form[action=?][method=?]", dataset_path(@dataset), "post" do

      assert_select "input#dataset_title[name=?]", "dataset[title]"

      # identifier is a hidden attribute for most users
      # assert_select "input#dataset_identifier[name=?]", "dataset[identifier]"

      assert_select "input#dataset_publisher[name=?]", "dataset[publisher]"

      assert_select "input#dataset_publication_year[name=?]", "dataset[publication_year]"

      # ordered_ids not currently being used
      # assert_select "input#dataset_creator_ordered_ids[name=?]", "dataset[creator_ordered_ids]"

      assert_select "input#dataset_license[name=?]", "dataset[license]"

      # key is a hidden attribute
      # assert_select "input#dataset_key[name=?]", "dataset[key]"

      assert_select "input#dataset_description[name=?]", "dataset[description]"

      # depositor is a hidden attribute
      # assert_select "input#dataset_depositor_name[name=?]", "dataset[depositor_name]"
      # assert_select "input#dataset_depositor_email[name=?]", "dataset[depositor_email]"

      # complete is a hidden attribute
      # assert_select "input#dataset_complete[name=?]", "dataset[complete]"

       assert_select "input#dataset_corresponding_creator_name[name=?]", "dataset[corresponding_creator_name]"

      # corresponding creator email is a hidden attribute
      # assert_select "input#dataset_corresponding_creator_email[name=?]", "dataset[corresponding_creator_email]"
    end
  end
end
