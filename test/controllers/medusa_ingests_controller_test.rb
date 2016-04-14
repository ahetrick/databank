require 'test_helper'

class MedusaIngestsControllerTest < ActionController::TestCase
  setup do
    @medusa_ingest = medusa_ingests(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:medusa_ingests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create medusa_ingest" do
    assert_difference('MedusaIngest.count') do
      post :create, medusa_ingest: {error_text: @medusa_ingest.error_text, idb_class: @medusa_ingest.idb_class, idb_identifier: @medusa_ingest.idb_identifier, medusa_path: @medusa_ingest.medusa_path, medusa_uuid: @medusa_ingest.medusa_uuid, request_status: @medusa_ingest.request_status, response_time: @medusa_ingest.response_time, staging_path: @medusa_ingest.staging_path}
    end

    assert_redirected_to medusa_ingest_path(assigns(:medusa_ingest))
  end

  test "should show medusa_ingest" do
    get :show, id: @medusa_ingest
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @medusa_ingest
    assert_response :success
  end

  test "should update medusa_ingest" do
    patch :update, id: @medusa_ingest, medusa_ingest: {error_text: @medusa_ingest.error_text, idb_class: @medusa_ingest.idb_class, idb_identifier: @medusa_ingest.idb_identifier, medusa_path: @medusa_ingest.medusa_path, medusa_uuid: @medusa_ingest.medusa_uuid, request_status: @medusa_ingest.request_status, response_time: @medusa_ingest.response_time, staging_path: @medusa_ingest.staging_path}
    assert_redirected_to medusa_ingest_path(assigns(:medusa_ingest))
  end

  test "should destroy medusa_ingest" do
    assert_difference('MedusaIngest.count', -1) do
      delete :destroy, id: @medusa_ingest
    end

    assert_redirected_to medusa_ingests_path
  end
end
