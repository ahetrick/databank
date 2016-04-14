require 'test_helper'

class FunderInfosControllerTest < ActionController::TestCase
  setup do
    @funder_info = funder_infos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:funder_infos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create funder_info" do
    assert_difference('FunderInfo.count') do
      post :create, funder_info: {code: @funder_info.code, display_position: @funder_info.display_position, identifier: @funder_info.identifier, identifier_scheme: @funder_info.identifier_scheme, name: @funder_info.name}
    end

    assert_redirected_to funder_info_path(assigns(:funder_info))
  end

  test "should show funder_info" do
    get :show, id: @funder_info
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @funder_info
    assert_response :success
  end

  test "should update funder_info" do
    patch :update, id: @funder_info, funder_info: {code: @funder_info.code, display_position: @funder_info.display_position, identifier: @funder_info.identifier, identifier_scheme: @funder_info.identifier_scheme, name: @funder_info.name}
    assert_redirected_to funder_info_path(assigns(:funder_info))
  end

  test "should destroy funder_info" do
    assert_difference('FunderInfo.count', -1) do
      delete :destroy, id: @funder_info
    end

    assert_redirected_to funder_infos_path
  end
end
