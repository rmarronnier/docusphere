class Notifications::NotificationDropdownComponent < ApplicationComponent
  def initialize(notifications:, unread_count: 0, dropdown_id: 'notifications-dropdown')
    @notifications = notifications
    @unread_count = unread_count
    @dropdown_id = dropdown_id
  end

  private

  attr_reader :notifications, :unread_count, :dropdown_id

  def badge_classes
    if unread_count > 0
      "absolute -top-1 -right-1 h-4 w-4 bg-red-500 text-white text-xs rounded-full flex items-center justify-center"
    else
      "hidden"
    end
  end

  def bell_classes
    if unread_count > 0
      "h-6 w-6 text-blue-600"
    else
      "h-6 w-6 text-gray-400"
    end
  end

  def display_count
    unread_count > 9 ? '9+' : unread_count.to_s
  end

  def notification_item_classes(notification)
    base = "flex items-start space-x-3 p-3 hover:bg-gray-50 transition-colors duration-150"
    base += " bg-blue-50" if notification.unread?
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

  def time_ago_short(notification)
    time_diff = Time.current - notification.created_at
    
    case time_diff
    when 0..59
      "#{time_diff.to_i}s"
    when 60..3599
      "#{(time_diff / 60).to_i}m"
    when 3600..86399
      "#{(time_diff / 3600).to_i}h"
    else
      "#{(time_diff / 86400).to_i}j"
    end
  end

  def truncated_message(message, length = 50)
    message.length > length ? "#{message.truncate(length)}..." : message
  end
end