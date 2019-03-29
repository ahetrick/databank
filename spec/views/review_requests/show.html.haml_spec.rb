require 'rails_helper'

RSpec.describe "review_requests/show", type: :view do
  before(:each) do
    @review_request = assign(:review_request, ReviewRequest.create!(
      :dataset_key => "Dataset Key"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Dataset Key/)
  end
end
