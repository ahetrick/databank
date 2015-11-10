require 'rails_helper'

RSpec.describe "datafiles/new", :type => :view do
  before(:each) do
    assign(:datafile, Datafile.new(
      :description => "MyString",
      :attachment => "MyString",
      :web_id => "MyString",
      :dataset_id => 1
    ))
  end

  it "renders new datafile form" do
    render

    assert_select "form[action=?][method=?]", datafiles_path, "post" do

      assert_select "input#datafile_description[name=?]", "datafile[description]"

      assert_select "input#datafile_attachment[name=?]", "datafile[attachment]"

      assert_select "input#datafile_web_id[name=?]", "datafile[web_id]"

      assert_select "input#datafile_dataset_id[name=?]", "datafile[dataset_id]"
    end
  end
end
