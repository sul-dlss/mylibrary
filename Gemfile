# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.0.1'

# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 2.5'

# Use Puma as the app server
gem 'puma', '~> 6.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

gem 'honeybadger'

gem 'config'

gem 'faraday' # Used by FolioClient
gem 'faraday-retry'

gem 'okcomputer'

gem 'warden'

gem 'nokogiri'

gem 'recaptcha'

gem 'global_alerts'

group :production do
  gem 'newrelic_rpm'
  gem 'pg'
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'axe-core-rspec'
  gem 'capybara'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'sinatra', require: false # used for faking the symphony api for integration tests
  gem 'timecop'
  gem 'warden-rspec-rails'
  gem 'webmock'
end

group :development do
  gem 'rack-mini-profiler', '~> 3.0'

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '~> 3.3'

  gem 'web-console', '>= 4.1.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Use Capistrano for deployment
group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'dlss-capistrano'
end

gem 'jsbundling-rails', '~> 1.3'
gem 'propshaft'
gem 'turbo-rails', '~> 2.0'
