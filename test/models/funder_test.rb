require 'test_helper'

class FunderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "should not save funder without dataset" do

    funder = Funder.new
    assert_not funder.save
  end

end
