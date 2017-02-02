require 'test_helper'

class TransfersControllerTest < ActionDispatch::IntegrationTest
  def test_routings
    assert_routing({ method: 'get', path: 'transfers' }, controller: 'transfers', action: 'index')
  end
end
