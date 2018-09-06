require 'rails_helper'

RSpec.describe "IngestResponses", type: :request do
  describe "GET /ingest_responses" do
    it "works! (now write some real specs)" do
      get ingest_responses_path
      expect(response).to have_http_status(200)
    end
  end
end
