# Money configuration
Money.default_currency = 'EUR'
Money.locale_backend = :currency

# Configuration pour l'affichage
MoneyRails.configure do |config|
  config.default_currency = :eur
  config.include_validations = true
  config.default_format = {
    no_cents: false,
    with_currency: true,
    format: '%n %u'
  }
end