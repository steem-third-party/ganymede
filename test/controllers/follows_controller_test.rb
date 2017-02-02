require 'test_helper'

class FollowsControllerTest < ActionDispatch::IntegrationTest
  def test_routings
    assert_routing({ method: 'get', path: 'follows' }, controller: 'follows', action: 'index')
  end
end
