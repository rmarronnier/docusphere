# Force loading of ImmoPromo helpers to avoid autoloading issues
if Rails.env.test?
  Rails.application.config.after_initialize do
    # Load all helpers from the engine
    Dir[Rails.root.join('engines/immo_promo/app/helpers/immo/promo/**/*.rb')].each do |file|
      require file
    end
  end
end