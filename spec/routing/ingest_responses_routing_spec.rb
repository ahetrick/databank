require "rails_helper"

RSpec.describe IngestResponsesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/ingest_responses").to route_to("ingest_responses#index")
    end

    it "routes to #new" do
      expect(:get => "/ingest_responses/new").to route_to("ingest_responses#new")
    end

    it "routes to #show" do
      expect(:get => "/ingest_responses/1").to route_to("ingest_responses#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/ingest_responses/1/edit").to route_to("ingest_responses#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/ingest_responses").to route_to("ingest_responses#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/ingest_responses/1").to route_to("ingest_responses#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/ingest_responses/1").to route_to("ingest_responses#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/ingest_responses/1").to route_to("ingest_responses#destroy", :id => "1")
    end
  end
end
