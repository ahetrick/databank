require "rails_helper"

RSpec.describe FeaturedResearchersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/featured_researchers").to route_to("featured_researchers#index")
    end

    it "routes to #new" do
      expect(:get => "/featured_researchers/new").to route_to("featured_researchers#new")
    end

    it "routes to #show" do
      expect(:get => "/featured_researchers/1").to route_to("featured_researchers#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/featured_researchers/1/edit").to route_to("featured_researchers#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/featured_researchers").to route_to("featured_researchers#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/featured_researchers/1").to route_to("featured_researchers#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/featured_researchers/1").to route_to("featured_researchers#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/featured_researchers/1").to route_to("featured_researchers#destroy", :id => "1")
    end

  end
end
