module RequestHelpers
  def sign_in_user(user = nil)
    user ||= create(:user)
    sign_in user
    user
  end
  
  def create_user_with_organization
    org = create(:organization)
    user = create(:user, organization: org)
    create(:user_profile, user: user, active: true)
    user
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end