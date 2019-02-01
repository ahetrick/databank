require 'rails_helper'

RSpec.describe "Contributors", type: :request do
  describe "GET /contributors" do
    it "works! (now write some real specs)" do
      get contributors_path
      expect(response).to have_http_status(200)
    end
  end
end
