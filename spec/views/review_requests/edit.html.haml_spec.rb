require 'rails_helper'

RSpec.describe "review_requests/edit", type: :view do
  before(:each) do
    @review_request = assign(:review_request, ReviewRequest.create!(
      :dataset_key => "MyString"
    ))
  end

  it "renders the edit review_request form" do
    render

    assert_select "form[action=?][method=?]", review_request_path(@review_request), "post" do

      assert_select "input#review_request_dataset_key[name=?]", "review_request[dataset_key]"
    end
  end
end
