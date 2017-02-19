require "test_helper"

class BasicWorkflowsTest < ActionDispatch::IntegrationTest
  def test_basic_workflow
    VCR.use_cassette('basic_workflows', record: RECORD_MODE) do
      visit '/'
      assert page.has_content?('Home'), 'expect "Home" text showing'
      assert page.has_content?('1 MV = 1M VESTS = 480.075 STEEM = $62.953'), 'expect "1 MV = 1M VESTS = 480.075 STEEM = $62.953" text showing'
      click_link 'Discussions'
      assert page.has_content?('Vote Ready'), 'expect "Vote Ready" text showing again'
    end
  end
end
