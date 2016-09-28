require 'test_helper'

class DatasetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "should generate key for empty new dataset" do
    dataset = Dataset.create
    assert_not_nil dataset.key, "Key was not generated for newly created dataset."
  end



end
