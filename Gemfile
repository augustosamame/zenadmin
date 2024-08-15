source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.0"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

gem "railsui", github: "getrailsui/railsui", branch: "main"

gem "interactor", "~> 3.0"
gem "cancancan", "~> 3.6.1"
gem "audited", "~> 5.7.0"
gem "sidekiq", "~> 7.3"
gem "dotenv-rails", "~> 2.8", require: 'dotenv/rails-now'
gem "cssbundling-rails", "~> 1.4.1"
gem "jsbundling-rails", "~> 1.3.1"
gem "devise", "~> 4.9.4"
gem 'devise-i18n', '~> 1.12.1'
gem 'httparty', '~> 0.22.0'
gem 'rollbar', '~> 3.5.2'
gem 'simple_form', '~> 5.3.1'
gem 'money-rails', '~> 1.15.0'
gem 'pg_search', '~> 2.3.7'
gem 'hashids'
gem 'aws-sdk-s3', '~> 1'
gem "shrine", "~> 3.6.0"
gem "ruby-vips", "~> 2.2.2"
gem "streamio-ffmpeg", "~> 3.0.2"
gem "rails_feather", "~> 0.1.0"
gem 'country_select', '~> 8.0'
gem 'twilio-ruby', '~> 7.2.3'
gem 'faker', '~> 3.4.2'
gem 'whenever', '~> 1.0.0', require: false
gem 'translate_enum', '~> 0.2.0'
gem 'jsonapi-serializer', '~> 2.2.0'
gem 'rubyzip', '~> 2.3.2'
gem 'devise-jwt', '~> 0.11.0'
gem 'jwt', '~> 2.8.2'
gem 'rack-cors', '~> 2.0.2', require: 'rack/cors'
gem 'geocoder', '~> 1.8.3'
gem 'kaminari', '~> 1.2.2'
gem 'web-push', '~> 3.0.1'


group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem 'rubocop', require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "awesome_print"
  gem 'byebug'
  gem 'bullet', '~> 7.2.0'
  gem 'bootstrap-generators', github: 'WorkBravely/bootstrap-generators', branch: 'master'
  gem 'rails-admin-scaffold', github: 'augustosamame/rails-admin-scaffold', branch: 'master'

  gem "capistrano", "~> 3.19.1", require: false
  gem "capistrano-rails", "~> 1.6.3", require: false
  gem 'capistrano-rails-console', require: false
  gem 'capistrano-yarn'
  #gem 'capistrano3-puma', '~> 5.2.0'
  gem 'capistrano3-puma', github: "seuros/capistrano-puma"
  #gem 'capistrano-rvm'
  gem 'capistrano-sidekiq'
  gem 'capistrano-dotenv', require: false
  gem 'capistrano-faster-assets', '~> 1.0'
end
