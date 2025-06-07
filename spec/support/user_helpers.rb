module UserHelpers
  def stub_user_permissions(user, permissions)
    allow(user).to receive(:has_permission?) do |permission|
      permissions.include?(permission)
    end
  end
end

RSpec.configure do |config|
  config.include UserHelpers
end