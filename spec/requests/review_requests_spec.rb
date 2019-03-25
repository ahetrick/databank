require 'rails_helper'

RSpec.describe "ReviewRequests", type: :request do
  describe "GET /review_requests" do
    it "works! (now write some real specs)" do
      get review_requests_path
      expect(response).to have_http_status(200)
    end
  end
end
