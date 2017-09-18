require 'rails_helper'

RSpec.describe "FeaturedResearchers", type: :request do
  describe "GET /featured_researchers" do
    it "works! (now write some real specs)" do
      get featured_researchers_path
      expect(response).to have_http_status(200)
    end
  end
end
