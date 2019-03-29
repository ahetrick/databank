require 'rails_helper'

RSpec.describe "review_requests/index", type: :view do
  before(:each) do
    assign(:review_requests, [
      ReviewRequest.create!(
        :dataset_key => "Dataset Key"
      ),
      ReviewRequest.create!(
        :dataset_key => "Dataset Key"
      )
    ])
  end

  it "renders a list of review_requests" do
    render
    assert_select "tr>td", :text => "Dataset Key".to_s, :count => 2
  end
end
