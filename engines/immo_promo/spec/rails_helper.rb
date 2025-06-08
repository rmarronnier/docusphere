# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

# Require the main app's environment
require File.expand_path('../../../../config/environment', __dir__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'

# Load main app support files
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Engine factories are loaded automatically by factory_bot_rails

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

# Load engine files
Dir[File.join(__dir__, '../app/controllers/**/*.rb')].each { |f| require f }
Dir[File.join(__dir__, '../app/models/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Warden::Test::Helpers, type: :system
  
  # Clean up Warden after system tests
  config.after(:each, type: :system) do
    Warden.test_reset!
  end
  
  # Configuration pour les contrôleurs de l'engine
  config.before(:each, type: :controller) do
    @routes = Immo::Promo::Engine.routes
  end
  
  # Configuration pour les tests système de l'engine
  config.before(:each, type: :system) do
    # Utilise les routes principales pour les tests système
    @routes = Rails.application.routes
  end
  
  # Configure ActiveJob to run inline for email tests
  config.around(:each, type: :service) do |example|
    perform_enqueued_jobs do
      example.run
    end
  end
  
  # Include ActionMailer test helpers
  config.include ActiveJob::TestHelper
end
