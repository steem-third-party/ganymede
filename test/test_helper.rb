ENV['RAILS_ENV'] ||= 'test'

if ENV["HELL_ENABLED"] || ENV['CODECLIMATE_REPO_TOKEN']
  require 'simplecov'
  if ENV['CODECLIMATE_REPO_TOKEN']
    SimpleCov.start CodeClimate::TestReporter.configuration.profile
  else
    SimpleCov.start
  end
  SimpleCov.merge_timeout 3600
end

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'capybara-screenshot/minitest'

if ENV["HELL_ENABLED"]
  require "minitest/hell"
else
  require "minitest/pride"
end

WebMock.disable_net_connect!(allow_localhost: true, allow: 'codeclimate.com:443')

phantomjs_logger = if ENV['TESTOPTS'].to_s.include?('--verbose')
  $stdout
else
  File.open("log/test_phantomjs.log", "a")
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    phantomjs: Phantomjs.path,
    phantomjs_logger: phantomjs_logger,
    debug: false,
    timeout: 15,
    js_errors: true,
    inspector: true,
    extensions: [
      'test/support/scripts/angular_errors.js'
    ]
  })
end

Capybara.javascript_driver = :poltergeist
Capybara.default_driver = :poltergeist
Capybara.default_max_wait_time = 15

Capybara::Screenshot.prune_strategy = { keep: 20 }

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Angular::DSL
  include Capybara::Screenshot::MiniTestPlugin
end
