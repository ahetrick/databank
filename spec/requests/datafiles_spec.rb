require 'rails_helper'

RSpec.describe "Datafiles", :type => :request do
  describe "GET /datafiles" do
    it "works! (now write some real specs)" do
      get datafiles_path
      expect(response.status).to be(200)
    end
  end
end
