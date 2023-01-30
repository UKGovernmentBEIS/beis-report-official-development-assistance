# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
ruby "2.7.7"

gem "acts_as_tree"
gem "addressable"
gem "aws-sdk-s3", "~> 1.118"
gem "bootsnap", ">= 1.1.0", require: false
gem "cssbundling-rails", "~> 1.1"
gem "govuk_design_system_formbuilder", "~> 3.3.0"
gem "haml-rails"
gem "high_voltage"
gem "ipaddr"
gem "jbuilder", "~> 2.11"
gem "jsbundling-rails", "~> 1.1"
gem "pg"
gem "mail-notify"
gem "monetize"
gem "mini_racer"
gem "nanoid"
gem "notifications-ruby-client"
gem "parser"
gem "pry-rails"
gem "puma", "~> 6.0"
gem "pundit"
gem "rollbar"
gem "rails", "~> 6.1.7"
gem "rollout"
gem "rollout-ui"
gem "redis"
gem "redis-namespace"
gem "redis-actionpack"
gem "redis-store"
gem "sidekiq", "~> 5.2"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "wicked"
gem "strip_attributes"

gem "breadcrumbs_on_rails"

# Authentication
gem "devise"
gem "devise-two-factor"
gem "devise-security"

group :development, :test do
  gem "brakeman"
  gem "bullet"
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "pry-byebug"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "foreman"
  gem "i18n-tasks", "~> 1.0.12"
  gem "rspec-rails"
  gem "standard"
end

group :development do
  gem "binding_of_caller"
  gem "better_errors"
  gem "html2haml"
  gem "listen", ">= 3.0.5", "< 3.9"
  gem "spring"
  gem "spring-commands-rspec"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "rails_layout"
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "capybara", ">= 2.15"
  gem "climate_control"
  gem "coveralls", require: false
  gem "database_cleaner"
  gem "fakeredis", require: false
  gem "launchy"
  gem "pundit-matchers", "~> 1.8.4"
  gem "rails-controller-testing"
  gem "shoulda-matchers"
  gem "selenium-webdriver"
  gem "webmock", "~> 3.18"
end

group :production do
  gem "lograge"
end
