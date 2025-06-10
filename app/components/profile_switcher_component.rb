class ProfileSwitcherComponent < ApplicationComponent
  attr_reader :user, :compact, :show_descriptions
  
  def initialize(user:, compact: false, show_descriptions: true)
    @user = user
    @compact = compact
    @show_descriptions = show_descriptions
  end
  
  def render?
    user_profiles.any?
  end
  
  private
  
  def user_profiles
    @user_profiles ||= begin
      if user.respond_to?(:user_profiles)
        user.user_profiles
      else
        []
      end
    end
  end
  
  def current_profile
    @current_profile ||= begin
      if user.respond_to?(:active_profile)
        user.active_profile
      elsif user.respond_to?(:current_profile)
        user.current_profile
      elsif user_profiles.any?
        user_profiles.find { |p| p.try(:active?) } || user_profiles.first
      else
        nil
      end
    end
  end
  
  def available_profiles
    @available_profiles ||= user_profiles.select do |profile|
      can_switch_to_profile?(profile.profile_type)
    end
  end
  
  def can_switch_to_profile?(profile_type)
    return true unless user.respond_to?(:can_switch_to_profile?)
    user.can_switch_to_profile?(profile_type)
  end
  
  def multiple_profiles?
    available_profiles.size > 1
  end
  
  def profile_label(profile_type)
    case profile_type
    when 'direction'
      'Direction'
    when 'chef_projet'
      'Chef de projet'
    when 'juriste'
      'Juriste'
    when 'architecte'
      'Architecte'
    when 'commercial'
      'Commercial'
    else
      profile_type.humanize
    end
  end
  
  def profile_description(profile_type)
    return nil unless show_descriptions
    
    case profile_type
    when 'direction'
      'Gestion stratégique et supervision'
    when 'chef_projet'
      'Pilotage opérationnel des projets'
    when 'juriste'
      'Conformité et affaires juridiques'
    when 'architecte'
      'Conception technique et plans'
    when 'commercial'
      'Gestion commerciale et ventes'
    else
      nil
    end
  end
  
  def profile_icon_class(profile_type)
    case profile_type
    when 'direction'
      'briefcase'
    when 'chef_projet'
      'clipboard-list'
    when 'juriste'
      'scale'
    when 'architecte'
      'cube'
    when 'commercial'
      'currency-dollar'
    else
      'user'
    end
  end
  
  def profile_color_class(profile_type)
    case profile_type
    when 'direction'
      'text-purple-600 bg-purple-100'
    when 'chef_projet'
      'text-blue-600 bg-blue-100'
    when 'juriste'
      'text-red-600 bg-red-100'
    when 'architecte'
      'text-green-600 bg-green-100'
    when 'commercial'
      'text-orange-600 bg-orange-100'
    else
      'text-gray-600 bg-gray-100'
    end
  end
  
  def activate_profile_path(profile)
    "/profiles/#{profile.id}/activate"
  end
  
  def component_classes
    classes = ['profile-switcher']
    classes << 'profile-switcher--compact' if compact
    classes.join(' ')
  end
end