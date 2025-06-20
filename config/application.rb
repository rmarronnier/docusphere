require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Docusphere
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Use Sidekiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # Internationalization
    config.i18n.default_locale = :fr
    config.i18n.available_locales = [ :fr, :en ]
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

    # Time zone
    config.time_zone = "Europe/Paris"

    # Document Processor Service Configuration
    config.document_processor_url = ENV.fetch("DOCUMENT_PROCESSOR_URL", "http://document-processor:8000")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Add engine paths for Immo::Promo controllers
    config.after_initialize do
      if defined?(ImmoPromo::Engine)
        engine_root = ImmoPromo::Engine.root
        config.autoload_paths += %W[
          #{engine_root}/app/controllers/immo
          #{engine_root}/app/models/immo
          #{engine_root}/app/helpers/immo
        ]
      end
    end
  end
end
