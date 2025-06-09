class Ui::UserAvatarComponent < ApplicationComponent
  def initialize(user:, size: "md", show_tooltip: false)
    @user = user
    @size = size
    @show_tooltip = show_tooltip
  end

  private

  attr_reader :user, :size, :show_tooltip
  
  def initials
    if user.first_name.present? && user.last_name.present?
      "#{user.first_name.first}#{user.last_name.first}".upcase
    elsif user.first_name.present?
      user.first_name.first.upcase
    elsif user.last_name.present?
      user.last_name.first.upcase
    else
      user.email.first.upcase
    end
  end
  
  def size_classes
    case size
    when "sm"
      "h-8 w-8 text-sm"
    when "lg"
      "h-12 w-12 text-lg"
    when "xl"
      "h-16 w-16 text-2xl"
    else
      "h-10 w-10 text-sm"
    end
  end
  
  def color_classes
    # Generate consistent color based on user ID
    colors = [
      "bg-indigo-100 text-indigo-700",
      "bg-blue-100 text-blue-700",
      "bg-green-100 text-green-700",
      "bg-yellow-100 text-yellow-700",
      "bg-red-100 text-red-700",
      "bg-purple-100 text-purple-700",
      "bg-pink-100 text-pink-700"
    ]
    colors[user.id % colors.length]
  end
end