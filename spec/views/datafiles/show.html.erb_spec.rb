require 'rails_helper'

RSpec.describe "datafiles/show", :type => :view do
  before(:each) do
    @datafile = assign(:datafile, Datafile.create!(
      :description => "Description",
      :attachment => "Attachment",
      :web_id => "Web",
      :dataset_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Attachment/)
    expect(rendered).to match(/Web/)
    expect(rendered).to match(/1/)
  end
end
