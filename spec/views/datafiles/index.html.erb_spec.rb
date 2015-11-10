require 'rails_helper'

RSpec.describe "datafiles/index", :type => :view do
  before(:each) do
    assign(:datafiles, [
      Datafile.create!(
        :description => "Description",
        :attachment => "Attachment",
        :web_id => "Web",
        :dataset_id => 1
      ),
      Datafile.create!(
        :description => "Description",
        :attachment => "Attachment",
        :web_id => "Web",
        :dataset_id => 1
      )
    ])
  end

  it "renders a list of datafiles" do
    render
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    assert_select "tr>td", :text => "Attachment".to_s, :count => 2
    assert_select "tr>td", :text => "Web".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
