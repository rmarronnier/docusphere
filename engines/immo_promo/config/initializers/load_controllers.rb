# Ensure controllers are loaded
Rails.application.config.to_prepare do
  # Load all Immo::Promo controllers
  Dir[ImmoPromo::Engine.root.join('app/controllers/immo/promo/**/*.rb')].each do |file|
    require_dependency file
  end
end
