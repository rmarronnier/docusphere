source "https://rubygems.org"

ruby "3.3.0"

gem "rails", "~> 7.1.2"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", "~> 6.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

# Active Storage & Image Processing
gem "image_processing", "~> 1.12"


# Background Jobs
gem "sidekiq", "~> 7.1"
gem "sidekiq-cron", "~> 1.10"

# Cache & Queues
gem "redis", "~> 5.0"

# Authentication & Authorization
gem "devise", "~> 4.9"
gem "pundit", "~> 2.4"

# File Processing
gem "carrierwave", "~> 3.0"
gem "carrierwave-base64", "~> 2.10"
gem "mini_magick", "~> 5.0"
gem "streamio-ffmpeg", "~> 3.0"

# Document Processing
gem "pdf-reader", "~> 2.13"
gem "prawn", "~> 2.5"
gem "combine_pdf", "~> 1.0"
gem "roo", "~> 2.10"
gem "rubyzip", "~> 2.3"
gem "mail", "~> 2.8"
gem "rtesseract", "~> 3.1"

# Search
gem "elasticsearch-model", "~> 7.2"
gem "elasticsearch-rails", "~> 7.2"
gem "searchkick", "~> 5.3"

# UI Components
gem "view_component", "~> 3.7"

# Internationalization
gem "rails-i18n", "~> 7.0"
gem "devise-i18n", "~> 1.11"

# Workflow & State Machine
gem "aasm", "~> 5.5"

# Other Features
gem "friendly_id", "~> 5.5"
gem "kaminari", "~> 1.2"
gem "audited", "~> 5.4"
gem "ancestry", "~> 4.3"
gem "acts-as-taggable-on", "~> 10.0"
gem "paper_trail", "~> 15.1"
gem "chronic", "~> 0.10" # Natural language date parsing
gem "ice_cube", "~> 0.16" # Recurring events
gem "money-rails", "~> 1.15" # Money management
gem "state_machines-activerecord", "~> 0.9" # State machines
gem "geocoder", "~> 1.8" # Geocoding for addresses

# Rails Engine for real estate project management
gem 'immo_promo', path: 'engines/immo_promo'

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.5"
  gem "parallel_tests", "~> 4.2"
end

group :development do
  gem "web-console"
  gem "listen", "~> 3.9"
  gem "spring"
  gem "spring-commands-rspec"
  # Component preview and documentation
  gem "lookbook", "~> 2.3"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 6.4"
  gem "rails-controller-testing"
  gem "pundit-matchers", "~> 3.1"
end

# Document processing gems (additional)
# Note: Using libreoffice command-line for Office document extraction due to yomu dependency conflict

# Content analysis gems
gem "monetize", "~> 1.13"         # Money parsing from text

# Security
gem "clamav-client", "~> 3.2"     # Virus scanning with ClamAV