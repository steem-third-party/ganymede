require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  def test_routings
    assert_routing({ method: 'get', path: 'accounts' }, controller: 'accounts', action: 'index')
  end
  
  def test_upvoted
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {upvoted: 'true'}
    end
  end
  
  def test_upvoted_voter
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {upvoted: 'true', voters: 'inertia'}
    end
    
    suggested_voters = assigns :suggested_voters
    assert suggested_voters.any?
    accounts = assigns :accounts
    assert accounts.any?
    
    assert_template :_nav
    assert_template :upvoted
    assert_response :success
  end
  
  def test_upvoted_download
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {upvoted: 'true', voters: 'inertia'}, format: 'text'
    end
  end
  
  def test_upvoted_with_rshares
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {upvoted: 'true', voters: 'steemed'}
    end
    
    assert_response :success
  end
  
  def test_downvoted
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {downvoted: 'true'}
    end
  end
  
  def test_downvoted_voter
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {downvoted: 'true', voters: 'inertia'}
    end
    
    suggested_voters = assigns :suggested_voters
    assert suggested_voters.any?
    accounts = assigns :accounts
    assert accounts.any?
    
    assert_template :_nav
    assert_template :downvoted
    assert_response :success
  end
  
  def test_upvoted_with_downvotes
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {upvoted: 'true', voters: 'abit'}
    end
    
    assert_response :success
  end
  
  def test_downvoted_download
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {downvoted: 'true', voters: 'inertia'}, format: 'text'
    end
    
    assert_response :success
  end
  
  def test_unvoted
    process :index, method: :get, params: {unvoted: 'true'}
  end
  
  def test_unvoted_voter
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {unvoted: 'true', voters: 'inertia'}
    end
    
    suggested_voters = assigns :suggested_voters
    refute suggested_voters, 'did not expect suggested voters'
    accounts = assigns :accounts
    assert accounts.any?
    
    assert_template :_nav
    assert_template :unvoted
    assert_response :success
  end
  
  def test_unvoted_download
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {unvoted: 'true', voters: 'inertia'}, format: 'text'
    end
    
    assert_response :success
  end
  
  def test_metadata
    process :index, method: :get, params: {metadata: 'true'}
  end
    
  def test_metadata_account_name
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {metadata: 'true', account_names: 'inertia'}
    end

    accounts = assigns :accounts
    assert accounts.any?
    
    assert_template :_nav
    assert_template :metadata
    assert_response :success
  end
  
  def test_metadata_download
    VCR.use_cassette('accounts_controller') do
      process :index, method: :get, params: {metadata: 'true', account_names: 'inertia'}, format: 'text'
    end
    
    assert_response :success
  end
end
