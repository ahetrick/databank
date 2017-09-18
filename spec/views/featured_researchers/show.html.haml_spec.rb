require 'rails_helper'

RSpec.describe "featured_researchers/show", type: :view do
  before(:each) do
    @featured_researcher = assign(:featured_researcher, FeaturedResearcher.create!(
      :name => "Name",
      :title => "Title",
      :bio => "MyText",
      :testimonial => "MyText",
      :binary => "Binary"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Binary/)
  end
end
