require 'test_helper'

class ApiDatasetControllerTest < ActionController::TestCase
  test "should get datafile" do
    get :datafile
    assert_response :success
  end

end
