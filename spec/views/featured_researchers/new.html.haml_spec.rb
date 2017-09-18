require 'rails_helper'

RSpec.describe "featured_researchers/new", type: :view do
  before(:each) do
    assign(:featured_researcher, FeaturedResearcher.new(
      :name => "MyString",
      :title => "MyString",
      :bio => "MyText",
      :testimonial => "MyText",
      :binary => "MyString"
    ))
  end

  it "renders new featured_researcher form" do
    render

    assert_select "form[action=?][method=?]", featured_researchers_path, "post" do

      assert_select "input#featured_researcher_name[name=?]", "featured_researcher[name]"

      assert_select "input#featured_researcher_title[name=?]", "featured_researcher[title]"

      assert_select "textarea#featured_researcher_bio[name=?]", "featured_researcher[bio]"

      assert_select "textarea#featured_researcher_testimonial[name=?]", "featured_researcher[testimonial]"

      assert_select "input#featured_researcher_binary[name=?]", "featured_researcher[binary]"
    end
  end
end
