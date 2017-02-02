require 'test_helper'

class DiscussionsControllerTest < ActionDispatch::IntegrationTest
  def test_routings
    assert_routing({ method: 'get', path: 'discussions' }, controller: 'discussions', action: 'index')
    assert_routing({ method: 'get', path: 'discussions/card' }, controller: 'discussions', action: 'card')
  end
end
