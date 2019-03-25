require "rails_helper"

RSpec.describe ReviewRequestsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/review_requests").to route_to("review_requests#index")
    end

    it "routes to #new" do
      expect(:get => "/review_requests/new").to route_to("review_requests#new")
    end

    it "routes to #show" do
      expect(:get => "/review_requests/1").to route_to("review_requests#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/review_requests/1/edit").to route_to("review_requests#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/review_requests").to route_to("review_requests#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/review_requests/1").to route_to("review_requests#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/review_requests/1").to route_to("review_requests#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/review_requests/1").to route_to("review_requests#destroy", :id => "1")
    end
  end
end
