module ImmoPromo
  class Engine < ::Rails::Engine
    isolate_namespace ImmoPromo
    
    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.assets false
      g.helper false
    end
    
    initializer "immo_promo.assets.precompile" do |app|
      app.config.assets.precompile += %w( immo_promo/application.css immo_promo/application.js )
    end
    
    initializer "immo_promo.factories", after: "factory_bot.set_factory_paths" do
      FactoryBot.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryBot)
    end
  end
end