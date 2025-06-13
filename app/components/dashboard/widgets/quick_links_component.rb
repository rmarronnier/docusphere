class Dashboard::Widgets::QuickLinksComponent < ViewComponent::Base
  def initialize(links:)
    @links = links || []
  end

  private

  attr_reader :links

  def any_links?
    links.any?
  end

  def icon_color_class(icon)
    case icon
    when 'cog'
      'text-gray-600 bg-gray-100'
    when 'users'
      'text-blue-600 bg-blue-100'
    when 'chart-bar'
      'text-green-600 bg-green-100'
    when 'folder'
      'text-yellow-600 bg-yellow-100'
    when 'search'
      'text-purple-600 bg-purple-100'
    when 'inbox'
      'text-indigo-600 bg-indigo-100'
    when 'user'
      'text-pink-600 bg-pink-100'
    when 'briefcase'
      'text-orange-600 bg-orange-100'
    when 'chart-line'
      'text-emerald-600 bg-emerald-100'
    else
      'text-gray-600 bg-gray-100'
    end
  end
end