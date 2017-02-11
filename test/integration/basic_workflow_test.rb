require "test_helper"

class BasicWorkflowsTest < ActionDispatch::IntegrationTest
  def setup
  end

  def test_basic_workflow
    VCR.use_cassette('basic_workflows') do
      visit '/'
      assert page.has_content?('Home'), 'expect "Home" text showing'
      click_link 'Discussions'
      assert page.has_content?('Vote Ready'), 'expect "Vote Ready" text showing again'
    end
  end
end
