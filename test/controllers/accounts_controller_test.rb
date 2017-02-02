require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  def test_routings
    assert_routing({ method: 'get', path: 'accounts' }, controller: 'accounts', action: 'index')
  end
end
