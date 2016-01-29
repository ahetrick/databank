require 'test_helper'

class FundersControllerTest < ActionController::TestCase
  setup do
    @funder = funders(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:funders)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create funder" do
    assert_difference('Funder.count') do
      post :create, funder: { dataset_id: @funder.dataset_id, grant: @funder.grant, identifier: @funder.identifier, identifier_scheme: @funder.identifier_scheme, name: @funder.name }
    end

    assert_redirected_to funder_path(assigns(:funder))
  end

  test "should show funder" do
    get :show, id: @funder
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @funder
    assert_response :success
  end

  test "should update funder" do
    patch :update, id: @funder, funder: { dataset_id: @funder.dataset_id, grant: @funder.grant, identifier: @funder.identifier, identifier_scheme: @funder.identifier_scheme, name: @funder.name }
    assert_redirected_to funder_path(assigns(:funder))
  end

  test "should destroy funder" do
    assert_difference('Funder.count', -1) do
      delete :destroy, id: @funder
    end

    assert_redirected_to funders_path
  end
end
