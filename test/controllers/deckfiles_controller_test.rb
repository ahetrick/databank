require 'test_helper'

class DeckfilesControllerTest < ActionController::TestCase
  setup do
    @deckfile = deckfiles(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:deckfiles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create deckfile" do
    assert_difference('Deckfile.count') do
      post :create, deckfile: { dataset_id: @deckfile.dataset_id, disposition: @deckfile.disposition, path: @deckfile.path, remove: @deckfile.remove }
    end

    assert_redirected_to deckfile_path(assigns(:deckfile))
  end

  test "should show deckfile" do
    get :show, id: @deckfile
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @deckfile
    assert_response :success
  end

  test "should update deckfile" do
    patch :update, id: @deckfile, deckfile: { dataset_id: @deckfile.dataset_id, disposition: @deckfile.disposition, path: @deckfile.path, remove: @deckfile.remove }
    assert_redirected_to deckfile_path(assigns(:deckfile))
  end

  test "should destroy deckfile" do
    assert_difference('Deckfile.count', -1) do
      delete :destroy, id: @deckfile
    end

    assert_redirected_to deckfiles_path
  end
end
