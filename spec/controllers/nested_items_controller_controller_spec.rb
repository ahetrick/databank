require 'rails_helper'

RSpec.describe NestedItemsControllerController, type: :controller do

  describe "GET #datafile_id:integer" do
    it "returns http success" do
      get :datafile_id:integer
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #parent_id:integer" do
    it "returns http success" do
      get :parent_id:integer
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #item_name:string" do
    it "returns http success" do
      get :item_name:string
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #media_type:string" do
    it "returns http success" do
      get :media_type:string
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #size:integer" do
    it "returns http success" do
      get :size:integer
      expect(response).to have_http_status(:success)
    end
  end

end
