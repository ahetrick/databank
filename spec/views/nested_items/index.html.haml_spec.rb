require 'rails_helper'

RSpec.describe "nested_items/index", type: :view do
  before(:each) do
    assign(:nested_items, [
      NestedItem.create!(
        :datafile_id => 2,
        :parent_id => 3,
        :item_name => "Item Name",
        :media_type => "Media Type",
        :size => 4
      ),
      NestedItem.create!(
        :datafile_id => 2,
        :parent_id => 3,
        :item_name => "Item Name",
        :media_type => "Media Type",
        :size => 4
      )
    ])
  end

  it "renders a list of nested_items" do
    render
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "Item Name".to_s, :count => 2
    assert_select "tr>td", :text => "Media Type".to_s, :count => 2
    assert_select "tr>td", :text => 4.to_s, :count => 2
  end
end
