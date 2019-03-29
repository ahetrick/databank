require 'rails_helper'

RSpec.describe "review_requests/new", type: :view do
  before(:each) do
    assign(:review_request, ReviewRequest.new(
      :dataset_key => "MyString"
    ))
  end

  it "renders new review_request form" do
    render

    assert_select "form[action=?][method=?]", review_requests_path, "post" do

      assert_select "input#review_request_dataset_key[name=?]", "review_request[dataset_key]"
    end
  end
end
