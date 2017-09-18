require 'rails_helper'

RSpec.describe "featured_researchers/index", type: :view do
  before(:each) do
    assign(:featured_researchers, [
      FeaturedResearcher.create!(
        :name => "Name",
        :title => "Title",
        :bio => "MyText",
        :testimonial => "MyText",
        :binary => "Binary"
      ),
      FeaturedResearcher.create!(
        :name => "Name",
        :title => "Title",
        :bio => "MyText",
        :testimonial => "MyText",
        :binary => "Binary"
      )
    ])
  end

  it "renders a list of featured_researchers" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "Binary".to_s, :count => 2
  end
end
