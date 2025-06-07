# Configure ClamAV client
if Rails.env.production? || Rails.env.development?
  # ClamAV client will be initialized when needed with connection params
  # Store configuration in Rails settings for later use
  Rails.application.config.clamav = {
    host: ENV.fetch('CLAMAV_HOST', 'localhost'),
    port: ENV.fetch('CLAMAV_PORT', 3310).to_i,
    timeout: 30
  }
end