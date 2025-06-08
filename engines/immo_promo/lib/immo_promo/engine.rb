module ImmoPromo
  class Engine < ::Rails::Engine
    # Remove isolate_namespace to allow using Immo::Promo controllers
    # isolate_namespace ImmoPromo

    # Ensure the lib directory is in the autoload path
    config.autoload_paths += %W[#{root}/lib]
    config.eager_load_paths += %W[#{root}/lib]

    # Configure autoloading for Immo namespace
    config.autoload_paths += %W[
      #{root}/app/controllers/immo
      #{root}/app/models/immo
      #{root}/app/helpers/immo
    ]
    
    # Also add to eager load paths
    config.eager_load_paths += %W[
      #{root}/app/controllers/immo
      #{root}/app/models/immo
      #{root}/app/helpers/immo
    ]

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.assets false
      g.helper false
    end

    initializer "immo_promo.assets.precompile" do |app|
      app.config.assets.precompile += %w[ immo_promo/application.css immo_promo/application.js ]
    end

    initializer "immo_promo.factories", after: "factory_bot.set_factory_paths" do
      FactoryBot.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryBot)
    end

    # Ensure Immo modules are loaded
    config.before_initialize do
      require 'immo'
      require 'immo/promo'
    end
    
    # Load models and controllers after initialization
    config.after_initialize do
      Dir[File.join(__dir__, '../../app/models/immo/promo/**/*.rb')].each do |file|
        require_dependency file
      end
      Dir[File.join(__dir__, '../../app/controllers/immo/promo/**/*.rb')].each do |file|
        require_dependency file
      end
    end
  end
end
