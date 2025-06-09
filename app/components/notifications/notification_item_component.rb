class Notifications::NotificationItemComponent < ApplicationComponent
  def initialize(notification:, show_actions: true, layout: :default)
    @notification = notification
    @show_actions = show_actions
    @layout = layout # :default, :compact, :detailed
  end

  private

  attr_reader :notification, :show_actions, :layout

  def container_classes
    base = "notification-item"
    base += " notification-item--unread" if notification.unread?
    base += " notification-item--urgent" if notification.urgent?
    base += " notification-item--#{layout}"
    
    case layout
    when :compact
      "#{base} flex items-center space-x-3 p-2 hover:bg-gray-50 rounded-md"
    when :detailed
      "#{base} bg-white shadow rounded-lg p-6 border-l-4 #{urgent_border_color}"
    else
      "#{base} flex items-start space-x-4 p-4 hover:bg-gray-50 border-b border-gray-200"
    end
  end

  def urgent_border_color
    notification.urgent? ? 'border-red-500' : 'border-blue-500'
  end

  def icon_container_classes
    base = "flex-shrink-0 flex items-center justify-center rounded-full"
    
    case layout
    when :compact
      "#{base} w-8 h-8"
    when :detailed
      "#{base} w-12 h-12"
    else
      "#{base} w-10 h-10"
    end
  end

  def icon_background_color
    if notification.urgent?
      'bg-red-100'
    elsif notification.unread?
      'bg-blue-100'
    else
      'bg-gray-100'
    end
  end

  def notification_url
    if notification.notifiable.present?
      case notification.notifiable
      when Document
        helpers.ged_document_path(notification.notifiable)
      when Space
        helpers.ged_space_path(notification.notifiable)
      when Folder
        helpers.ged_folder_path(notification.notifiable)
      else
        helpers.notification_path(notification)
      end
    else
      helpers.notification_path(notification)
    end
  end

  def title_classes
    base = "font-medium text-gray-900"
    
    case layout
    when :compact
      "#{base} text-sm"
    when :detailed
      "#{base} text-lg"
    else
      "#{base} text-sm"
    end
  end

  def message_classes
    base = "text-gray-600"
    
    case layout
    when :compact
      "#{base} text-xs"
    when :detailed
      "#{base} text-base"
    else
      "#{base} text-sm"
    end
  end

  def meta_classes
    base = "text-gray-500"
    
    case layout
    when :compact
      "#{base} text-xs"
    when :detailed
      "#{base} text-sm"
    else
      "#{base} text-xs"
    end
  end

  def category_badge_color(category)
    case category&.to_sym
    when :documents
      'bg-blue-100 text-blue-800'
    when :projects
      'bg-green-100 text-green-800'
    when :stakeholders
      'bg-purple-100 text-purple-800'
    when :permits
      'bg-yellow-100 text-yellow-800'
    when :budgets
      'bg-orange-100 text-orange-800'
    when :risks
      'bg-red-100 text-red-800'
    when :authorization
      'bg-indigo-100 text-indigo-800'
    when :system
      'bg-gray-100 text-gray-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def formatted_time
    case layout
    when :compact
      notification.created_at.strftime('%H:%M')
    when :detailed
      notification.created_at.strftime('%d/%m/%Y à %H:%M')
    else
      notification.time_ago
    end
  end

  def truncate_message?
    layout == :compact
  end

  def show_detailed_data?
    layout == :detailed && notification.formatted_data.any?
  end

  def notifiable_info
    return nil unless notification.notifiable.present?
    
    {
      type: notification.notifiable.class.name.humanize,
      title: notifiable_title,
      url: notification_url
    }
  end

  def notifiable_title
    notifiable = notification.notifiable
    
    if notifiable.respond_to?(:title)
      notifiable.title
    elsif notifiable.respond_to?(:name)
      notifiable.name
    elsif notifiable.respond_to?(:full_name)
      notifiable.full_name
    else
      "##{notifiable.id}"
    end
  end

  def action_button_classes
    "inline-flex items-center px-2 py-1 border border-transparent text-xs font-medium rounded text-gray-700 bg-gray-100 hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 transition-colors duration-150"
  end
end