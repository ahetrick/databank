require 'test_helper'

class BinariesControllerTest < ActionController::TestCase
  setup do
    @binary = binaries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:binaries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create binary" do
    assert_difference('Binary.count') do
      post :create, binary: { attachment: @binary.datafile, dataset_id: @binary.dataset_id }
    end

    assert_redirected_to binary_path(assigns(:binary))
  end

  test "should show binary" do
    get :show, id: @binary
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @binary
    assert_response :success
  end

  test "should update binary" do
    patch :update, id: @binary, binary: { attachment: @binary.datafile, dataset_id: @binary.dataset_id }
    assert_redirected_to binary_path(assigns(:binary))
  end

  test "should destroy binary" do
    assert_difference('Binary.count', -1) do
      delete :destroy, id: @binary
    end

    assert_redirected_to binaries_path
  end
end
