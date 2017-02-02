require "test_helper"

class BasicWorkflowsTest < ActionDispatch::IntegrationTest
  def setup
  end

  def test_basic_workflow
    visit '/'
    assert page.has_content?('Sign Up'), 'expect "Sign Up" text showing'
    click_link 'Discussions'
    assert page.has_content?('Sign Up'), 'expect "Sign Up" text showing again'
    click_link 'Log In'
    assert page.has_content?('Log In'), 'expect "Log In" text showing again'
  end
end
