require 'test_helper'

class TransfersControllerTest < ActionController::TestCase
  def test_routings
    assert_routing({ method: 'get', path: 'transfers' }, controller: 'transfers', action: 'index')
  end
end
