require 'rails_helper'

RSpec.describe "NestedItems", type: :request do
  describe "GET /nested_items" do
    it "works! (now write some real specs)" do
      get nested_items_path
      expect(response).to have_http_status(200)
    end
  end
end
