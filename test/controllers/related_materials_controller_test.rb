require 'test_helper'

class RelatedMaterialsControllerTest < ActionController::TestCase
  setup do
    @related_material = related_materials(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:related_materials)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create related_material" do
    assert_difference('RelatedMaterial.count') do
      post :create, related_material: { availability: @related_material.availability, citation: @related_material.citation, dataset_id: @related_material.dataset_id, link: @related_material.link, materialType: @related_material.materialType, uri: @related_material.uri, uri_type: @related_material.uri_type }
    end

    assert_redirected_to related_material_path(assigns(:related_material))
  end

  test "should show related_material" do
    get :show, id: @related_material
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @related_material
    assert_response :success
  end

  test "should update related_material" do
    patch :update, id: @related_material, related_material: { availability: @related_material.availability, citation: @related_material.citation, dataset_id: @related_material.dataset_id, link: @related_material.link, materialType: @related_material.materialType, uri: @related_material.uri, uri_type: @related_material.uri_type }
    assert_redirected_to related_material_path(assigns(:related_material))
  end

  test "should destroy related_material" do
    assert_difference('RelatedMaterial.count', -1) do
      delete :destroy, id: @related_material
    end

    assert_redirected_to related_materials_path
  end
end
