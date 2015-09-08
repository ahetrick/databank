require 'rails_helper'

RSpec.describe "Datasets", :type => :request do
  describe "GET /datasets" do
    it "works! (now write some real specs)" do
      get datasets_path
      expect(response.status).to be(200)
    end
  end
end
