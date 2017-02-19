require 'test_helper'

class TickersControllerTest < ActionController::TestCase
  def test_routings
    assert_routing({ method: 'get', path: 'tickers' }, controller: 'tickers', action: 'index')
    assert_routing({ method: 'get', path: 'tickers/BTC_STEEM' }, controller: 'tickers', action: 'show', pair: 'BTC_STEEM')
  end
  
  def test_index
    VCR.use_cassette('tickers_controller', record: RECORD_MODE) do
      process :index, method: :get
    end
  end
  
  def test_show
    VCR.use_cassette('tickers_controller', record: RECORD_MODE) do
      process :show, method: :get, params: {pair: 'BTC_STEEM'}
    end
  end
  
  def test_show_rss
    VCR.use_cassette('tickers_controller', record: RECORD_MODE) do
      process :show, method: :get, params: {pair: 'BTC_STEEM'}, format: :rss
    end
  end
  
  def test_show_atom
    VCR.use_cassette('tickers_controller', record: RECORD_MODE) do
      process :show, method: :get, params: {pair: 'BTC_STEEM'}, format: :atom
    end
  end
  
  def test_show_png
    VCR.use_cassette('tickers_controller', record: RECORD_MODE) do
      process :show, method: :get, params: {pair: 'BTC_STEEM'}, format: :png
    end
  end
end
