require 'rails_helper'

RSpec.describe "Identities", type: :request do
  describe "GET /identities" do
    it "works! (now write some real specs)" do
      get identities_path
      expect(response).to have_http_status(200)
    end
  end
end
