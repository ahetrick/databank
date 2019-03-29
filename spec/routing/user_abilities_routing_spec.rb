require "rails_helper"

RSpec.describe UserAbilitiesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/user_abilities").to route_to("user_abilities#index")
    end

    it "routes to #new" do
      expect(:get => "/user_abilities/new").to route_to("user_abilities#new")
    end

    it "routes to #show" do
      expect(:get => "/user_abilities/1").to route_to("user_abilities#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/user_abilities/1/edit").to route_to("user_abilities#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/user_abilities").to route_to("user_abilities#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/user_abilities/1").to route_to("user_abilities#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/user_abilities/1").to route_to("user_abilities#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/user_abilities/1").to route_to("user_abilities#destroy", :id => "1")
    end
  end
end
