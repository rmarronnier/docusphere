require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'factory_bot_rails'
require 'faker'
require 'shoulda/matchers'
require 'rails-controller-testing'
require 'view_component/test_helpers'
require 'capybara/rspec'
require 'pundit/matchers'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Load support files
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Disable Searchkick for tests
  config.before(:suite) do
    Searchkick.disable_callbacks
  end
  
  # Disable Audited for tests to avoid TimeWithZone serialization issues
  config.before(:suite) do
    Audited.auditing_enabled = false
  end
  
  # Configure ActiveJob to run inline for email tests
  config.around(:each, type: :service) do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  # FactoryBot configuration
  config.include FactoryBot::Syntax::Methods

  # Shoulda Matchers configuration
  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
  
  # Pundit Matchers configuration
  config.include Pundit::Matchers, type: :policy
  
  # Explicitly require pundit/rspec for policy tests
  require 'pundit/rspec'

  # Devise test helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Warden::Test::Helpers, type: :system
  
  # Clean up Warden after system tests
  config.after(:each, type: :system) do
    Warden.test_reset!
  end
  
  # ActiveJob test helpers
  config.include ActiveJob::TestHelper, type: :service

  # ViewComponent test helpers
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
  
  # Rails Controller Testing
  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end

  # Clean up uploaded files after tests
  config.after(:each) do
    FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end