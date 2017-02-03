require 'test_helper'

class StaticControllerTest < ActionController::TestCase
  def test_routings
    assert_routing({ method: 'get', path: '' }, controller: 'static', action: 'index')
    assert_routing({ method: 'get', path: 'favicon' }, controller: 'static', action: 'favicon')
  end
end
