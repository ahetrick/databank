require "rails_helper"

RSpec.describe DatabankTasksController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/databank_tasks").to route_to("databank_tasks#index")
    end

    it "routes to #new" do
      expect(:get => "/databank_tasks/new").to route_to("databank_tasks#new")
    end

    it "routes to #show" do
      expect(:get => "/databank_tasks/1").to route_to("databank_tasks#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/databank_tasks/1/edit").to route_to("databank_tasks#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/databank_tasks").to route_to("databank_tasks#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/databank_tasks/1").to route_to("databank_tasks#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/databank_tasks/1").to route_to("databank_tasks#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/databank_tasks/1").to route_to("databank_tasks#destroy", :id => "1")
    end
  end
end
