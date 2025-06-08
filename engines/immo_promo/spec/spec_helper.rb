# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../test/dummy/config/environment', __dir__)
require 'rspec/rails'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end