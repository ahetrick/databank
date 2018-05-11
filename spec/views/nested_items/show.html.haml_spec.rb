require 'rails_helper'

RSpec.describe "nested_items/show", type: :view do
  before(:each) do
    @nested_item = assign(:nested_item, NestedItem.create!(
      :datafile_id => 2,
      :parent_id => 3,
      :item_name => "Item Name",
      :media_type => "Media Type",
      :size => 4
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/Item Name/)
    expect(rendered).to match(/Media Type/)
    expect(rendered).to match(/4/)
  end
end
