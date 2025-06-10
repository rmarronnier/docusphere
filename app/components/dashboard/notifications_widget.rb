class Dashboard::NotificationsWidget < ApplicationComponent
  attr_reader :widget_data, :user
  
  def initialize(widget_data:, user:)
    @widget_data = widget_data
    @user = user
  end
  
  private
  
  def notifications
    @notifications ||= widget_data[:data][:notifications] || []
  end
  
  def notification_limit
    widget_data.dig(:config, :limit) || 5
  end
  
  def total_count
    widget_data.dig(:data, :total_count) || notifications.size
  end
  
  def unread_count
    widget_data.dig(:data, :unread_count) || notifications.count { |n| !n[:read] }
  end
  
  def loading?
    widget_data[:loading] == true
  end
  
  def has_more_notifications?
    total_count > notification_limit
  end
  
  def urgency_class(urgency)
    case urgency
    when 'high'
      'bg-red-50 border-red-200'
    when 'low'
      'bg-gray-50 border-gray-200'
    else
      'bg-blue-50 border-blue-200'
    end
  end
  
  def notification_icon_class(type)
    case type
    when 'document_shared'
      'share'
    when 'validation_required'
      'badge-check'
    when 'comment_added'
      'chat-bubble-left-right'
    when 'task_assigned'
      'clipboard-document-list'
    when 'deadline_approaching'
      'clock'
    else
      'bell'
    end
  end
  
  def relative_time(timestamp)
    return '' unless timestamp
    
    seconds = Time.current - timestamp
    
    case seconds
    when 0..59
      'à l\'instant'
    when 60..3599
      minutes = (seconds / 60).round
      "il y a #{minutes} minute#{'s' if minutes > 1}"
    when 3600..86399
      hours = (seconds / 3600).round
      "il y a environ #{hours == 1 ? 'une' : hours} heure#{'s' if hours > 1}"
    when 86400..604799
      days = (seconds / 86400).round
      "il y a #{days} jour#{'s' if days > 1}"
    else
      timestamp.strftime('%d/%m/%Y')
    end
  end
  
  def notification_path(notification)
    "/notifications/#{notification[:id]}"
  end
  
  def all_notifications_path
    '/notifications'
  end
  
  def mark_as_read_path(notification)
    "/notifications/#{notification[:id]}/mark_as_read"
  end
end