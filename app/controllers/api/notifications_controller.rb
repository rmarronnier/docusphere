class Api::NotificationsController < Api::BaseController
  def index
    notifications = current_user.notifications
                               .recent
                               .limit(20)
    
    render_json({
      notifications: notifications.map { |notif| notification_json(notif) }
    })
  end
  
  private
  
  def notification_json(notification)
    {
      id: notification.id,
      title: notification.title,
      message: notification.message,
      read_at: notification.read_at,
      created_at: notification.created_at,
      url: notification_path(notification)
    }
  end
end