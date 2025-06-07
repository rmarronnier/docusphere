module FixtureFileHelpers
  def fixture_file_upload(path, mime_type)
    Rack::Test::UploadedFile.new(Rails.root.join(path), mime_type)
  end
end

RSpec.configure do |config|
  config.include FixtureFileHelpers, type: :controller
  config.include FixtureFileHelpers, type: :request
end