class Ui::UserAvatarComponent < ApplicationComponent
  def initialize(user:, size: :md, show_status: false, status: :offline, href: nil, show_tooltip: true, **options)
    @user = user
    @size = size
    @show_status = show_status
    @status = status # :online, :offline, :busy, :away
    @href = href
    @show_tooltip = show_tooltip
    @options = options
  end

  private

  attr_reader :user, :size, :show_status, :status, :href, :show_tooltip, :options
  
  def initials
    return "?" unless user
    
    # Try to use name field first (common in many apps)
    if user.respond_to?(:name) && user.name.present?
      names = user.name.split
      if names.size > 1
        "#{names.first[0]}#{names.last[0]}".upcase
      else
        names.first[0..1].upcase
      end
    # Fallback to first_name/last_name
    elsif user.respond_to?(:first_name) && user.first_name.present?
      if user.respond_to?(:last_name) && user.last_name.present?
        "#{user.first_name.first}#{user.last_name.first}".upcase
      else
        user.first_name[0..1].upcase
      end
    elsif user.respond_to?(:last_name) && user.last_name.present?
      user.last_name[0..1].upcase
    elsif user.respond_to?(:email) && user.email.present?
      user.email[0..1].upcase
    else
      "?"
    end
  end
  
  def size_classes
    case size
    when :xs
      "h-6 w-6 text-xs"
    when :sm
      "h-8 w-8 text-sm"
    when :md
      "h-10 w-10 text-sm"
    when :lg
      "h-12 w-12 text-base"
    when :xl
      "h-16 w-16 text-xl"
    when :"2xl"
      "h-20 w-20 text-2xl"
    else
      "h-10 w-10 text-sm"
    end
  end
  
  def color_classes
    # Generate consistent color based on user ID
    colors = [
      "bg-gradient-to-br from-primary-500 to-primary-600",
      "bg-gradient-to-br from-purple-500 to-purple-600",
      "bg-gradient-to-br from-pink-500 to-pink-600",
      "bg-gradient-to-br from-indigo-500 to-indigo-600",
      "bg-gradient-to-br from-blue-500 to-blue-600",
      "bg-gradient-to-br from-teal-500 to-teal-600",
      "bg-gradient-to-br from-green-500 to-green-600",
      "bg-gradient-to-br from-yellow-500 to-yellow-600",
      "bg-gradient-to-br from-orange-500 to-orange-600",
      "bg-gradient-to-br from-red-500 to-red-600"
    ]
    
    # Generate consistent color based on user ID or email
    hash_input = user&.id || user&.email || "default"
    hash_value = hash_input.to_s.sum
    colors[hash_value % colors.length]
  end
  
  def wrapper_tag
    href.present? ? :a : :div
  end

  def wrapper_classes
    classes = ["relative inline-block"]
    classes << "group" if href.present?
    classes << options[:class] if options[:class]
    classes.join(" ")
  end

  def avatar_classes
    classes = ["inline-flex items-center justify-center font-medium text-white rounded-full", size_classes, color_classes]
    
    # Add ring for links
    if href.present?
      classes << "ring-2 ring-white group-hover:ring-4 transition-all duration-200"
    end
    
    # Add shadow for larger sizes
    if [:lg, :xl, :"2xl"].include?(size)
      classes << "shadow-lg"
    end
    
    classes.join(" ")
  end

  def status_classes
    base_classes = ["absolute bottom-0 right-0 block rounded-full ring-2 ring-white"]
    
    # Size classes
    case size
    when :xs
      base_classes << "h-1.5 w-1.5"
    when :sm
      base_classes << "h-2 w-2"
    when :md
      base_classes << "h-2.5 w-2.5"
    when :lg
      base_classes << "h-3 w-3"
    when :xl
      base_classes << "h-4 w-4"
    when :"2xl"
      base_classes << "h-5 w-5"
    else
      base_classes << "h-2.5 w-2.5"
    end
    
    # Status color
    case status
    when :online
      base_classes << "bg-success-400"
    when :busy
      base_classes << "bg-danger-400"
    when :away
      base_classes << "bg-warning-400"
    else
      base_classes << "bg-gray-300"
    end
    
    base_classes.join(" ")
  end
  
  def tooltip_text
    if user
      user.respond_to?(:name) ? user.name : user.email
    else
      "Unknown User"
    end
  end
end