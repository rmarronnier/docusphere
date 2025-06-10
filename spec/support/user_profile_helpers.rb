module UserProfileHelpers
  def setup_user_with_profile(user, profile_type)
    # Use singleton method to avoid RSpec mocking issues
    profile = OpenStruct.new(profile_type: profile_type, active: true)
    
    user.define_singleton_method(:user_profiles) do
      [profile]
    end
    user.define_singleton_method(:current_profile) do
      profile
    end
    user.define_singleton_method(:active_profile) do
      profile
    end
  end
end

RSpec.configure do |config|
  config.include UserProfileHelpers, type: :component
end