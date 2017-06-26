source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.1'
# Use sqlite3 as the database for Active Record
#gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Access the STEEM blockchain.
gem 'radiator'
gem 'steemdata-rb', require: 'steemdata'

# Adds general machine learning capabilities.
gem 'ai4r'

# Templates
gem 'haml'
gem 'rdiscount'

#Assets

gem 'bootstrap-glyphicons', '~> 0.0.1'
# Wraps the Angular.js UI Bootstrap library.
gem 'angular-ui-bootstrap-rails'

source 'https://rails-assets.org' do
  gem 'rails-assets-bootstrap', '~> 4.0.0.alpha.6'
  gem 'rails-assets-jquery', '~> 2.2.4'
  gem 'rails-assets-jquery-ujs', '~> 1.2.0'
  gem 'rails-assets-angular', '~> 1.5.7'
  gem 'rails-assets-angular-flash-alert', '~> 1.1.1'
  gem 'rails-assets-nprogress', '~> 0.2.0'
  # Tooltips and popovers depend on tether for positioning.
  gem 'rails-assets-tether', '>= 1.3.2'
end

gem 'listen'

# Capture pages for feeds.
gem 'imgkit'
gem 'wkhtmltoimage-binary'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'pry-rails'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller', require: false
  gem 'rack-mini-profiler', require: false
  gem 'flamegraph', require: false
  gem 'fast_stack', require: false
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# gem 'newrelic_rpm'

group :test do
  gem 'capybara-angular'
  gem 'capybara-screenshot'
  gem 'poltergeist', '~> 1.13.0'
  gem 'phantomjs', require: 'phantomjs/poltergeist'
  gem 'minitest'
  gem 'minitest-line'
  gem 'simplecov', require: false
  gem 'webmock', require: false
  gem 'codeclimate-test-reporter'
  # See: https://github.com/myronmarston/vcr
  gem 'vcr'
  gem 'rails-controller-testing'
end
