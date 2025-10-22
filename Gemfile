source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.7"

gem "activeadmin", "~> 3.2.5"
gem "activeadmin_addons", "~> 1.10.0"
gem "active_admin_datetimepicker", "~> 0.5.0"
gem "active_admin_theme", "~> 1.1.4"
gem "bootsnap", require: false
gem "brakeman", "~> 6.0"
gem "bundler-audit", "~> 0.9.1"
gem "cloudinary", "~> 1.28"
gem "devise", "~> 4.9"
gem "font-awesome-sass", "~> 6.5"
gem "has_scope", "~> 0.8"
gem "httparty", "~> 0.21"
gem "importmap-rails", "~> 1.2"
gem "jbuilder", "~> 2.11"
gem "lograge", "~> 0.14"
gem "pagy", "~> 6.0"
gem "pg", "~> 1.1"
gem "pg_search", "~> 2.3"
gem "postmark-rails", "~> 0.22"
gem "puma", "~> 5.0"
gem "pundit", "~> 2.3"
gem "rails", "~> 7.1.3.4"
gem "rails-i18n", "~> 7.0.0"
gem "redis", "~> 4.0"
gem "rexml", "~> 3.2"
gem "sassc-rails", "~> 2.1"
gem "sidekiq", "~> 7.2"
gem "sidekiq-cron", "~> 1.11"
gem "simple_form", github: "heartcombo/simple_form"
gem "sprockets-rails", "~> 3.4"
gem "stimulus-rails", "~> 1.3"
gem "turbo-rails", "~> 1.5"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "view_component", "~> 3.8"

group :development, :test, :staging do
  gem "faker", "~> 3.2"
end

group :development, :test do
  gem "database_cleaner-active_record", "~> 2.1"
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv-rails", "~> 2.8"
  gem "factory_bot_rails", "~> 6.4"
  gem "rspec-rails", "~> 6.0.0"
  gem "standard"
end

group :development do
  gem "bullet", "~> 7.1"
  gem "letter_opener", "~> 1.8"
  gem "lookbook", "~> 2.3"
  gem "pry-byebug", "~> 3.10"
  gem "rack-mini-profiler", "~> 3.1"
  gem "web-console", "~> 4.2"
end

group :test do
  gem "capybara", "~> 3.39"
  gem "selenium-webdriver", "~> 4.10"
  gem "shoulda-matchers", "~> 5.0"
  gem "webdrivers", "~> 5.3"
end

gem "wicked_pdf", "~> 2.8"
gem "wkhtmltopdf-binary", "~> 0.12.6"
gem 'rswag'

# API & React Integration
gem 'jwt'                           # JWT token generation/validation
gem 'rack-cors'                     # CORS support for React apps
gem 'active_model_serializers'     # JSON API responses