require "rails_helper"

RSpec.describe DatafilesController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/datafiles").to route_to("datafiles#index")
    end

    it "routes to #new" do
      expect(:get => "/datafiles/new").to route_to("datafiles#new")
    end

    it "routes to #show" do
      expect(:get => "/datafiles/1").to route_to("datafiles#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/datafiles/1/edit").to route_to("datafiles#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/datafiles").to route_to("datafiles#create")
    end

    it "routes to #update" do
      expect(:put => "/datafiles/1").to route_to("datafiles#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/datafiles/1").to route_to("datafiles#destroy", :id => "1")
    end

  end
end
