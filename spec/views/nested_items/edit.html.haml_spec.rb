require 'rails_helper'

RSpec.describe "nested_items/edit", type: :view do
  before(:each) do
    @nested_item = assign(:nested_item, NestedItem.create!(
      :datafile_id => 1,
      :parent_id => 1,
      :item_name => "MyString",
      :media_type => "MyString",
      :size => 1
    ))
  end

  it "renders the edit nested_item form" do
    render

    assert_select "form[action=?][method=?]", nested_item_path(@nested_item), "post" do

      assert_select "input#nested_item_datafile_id[name=?]", "nested_item[datafile_id]"

      assert_select "input#nested_item_parent_id[name=?]", "nested_item[parent_id]"

      assert_select "input#nested_item_item_name[name=?]", "nested_item[item_name]"

      assert_select "input#nested_item_media_type[name=?]", "nested_item[media_type]"

      assert_select "input#nested_item_size[name=?]", "nested_item[size]"
    end
  end
end
