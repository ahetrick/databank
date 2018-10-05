require 'rails_helper'

RSpec.describe "DatabankTasks", type: :request do
  describe "GET /databank_tasks" do
    it "works! (now write some real specs)" do
      get databank_tasks_path
      expect(response).to have_http_status(200)
    end
  end
end
