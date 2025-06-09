class Notifications::NotificationListComponent < ApplicationComponent
  def initialize(notifications:, show_actions: true, compact: false)
    @notifications = notifications
    @show_actions = show_actions
    @compact = compact
  end

  private

  attr_reader :notifications, :show_actions, :compact

  def list_classes
    base = "divide-y divide-gray-200"
    compact ? "#{base} space-y-1" : "#{base} space-y-3"
  end

  def item_classes(notification)
    base = "flex items-start space-x-3 p-4 hover:bg-gray-50 transition-colors duration-150"
    base += " bg-blue-50" if notification.unread?
    base += " border-l-4 border-red-500" if notification.urgent?
    base
  end

  def notification_url(notification)
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

  def time_display(notification)
    if compact
      notification.created_at.strftime('%H:%M')
    else
      notification.time_ago
    end
  end

  def truncate_message(message, length = nil)
    return message if length.nil?
    return message if message.length <= length
    "#{message.truncate(length)}..."
  end
end