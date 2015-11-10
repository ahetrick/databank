require 'rails_helper'

RSpec.describe "datafiles/edit", :type => :view do
  before(:each) do
    @datafile = assign(:datafile, Datafile.create!(
      :description => "MyString",
      :attachment => "MyString",
      :web_id => "MyString",
      :dataset_id => 1
    ))
  end

  it "renders the edit datafile form" do
    render

    assert_select "form[action=?][method=?]", datafile_path(@datafile), "post" do

      assert_select "input#datafile_description[name=?]", "datafile[description]"

      assert_select "input#datafile_attachment[name=?]", "datafile[attachment]"

      assert_select "input#datafile_web_id[name=?]", "datafile[web_id]"

      assert_select "input#datafile_dataset_id[name=?]", "datafile[dataset_id]"
    end
  end
end
