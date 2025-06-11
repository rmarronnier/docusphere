module NotificationService::UserUtilities
    extend ActiveSupport::Concern
    
    class_methods do
      def notify_system_announcement(users, title, message, data: {})
        users.each do |user|
          Notification.notify_user(
            user,
            :system_announcement,
            title,
            message,
            data: data.merge(announcement_type: 'system')
          )
        end
      end
      
      def notify_maintenance_scheduled(users, start_time, duration, description = nil)
        message = "Maintenance programmée le #{start_time.strftime('%d/%m/%Y à %H:%M')} (durée: #{duration})"
        message += "\n#{description}" if description.present?
        
        users.each do |user|
          Notification.notify_user(
            user,
            :maintenance_scheduled,
            "Maintenance programmée",
            message,
            data: {
              start_time: start_time,
              duration: duration,
              description: description
            }
          )
        end
      end
      
      def mark_all_read_for_user(user)
        user.notifications.unread.update_all(read_at: Time.current)
      end

      def unread_count_for_user(user)
        user.notifications.unread.count
      end

      def recent_notifications_for_user(user, limit: 10)
        user.notifications.recent.limit(limit)
      end

      def notifications_by_category_for_user(user, category, limit: 20)
        user.notifications.by_category(category).recent.limit(limit)
      end

      def urgent_notifications_for_user(user)
        urgent_types = [
          'budget_exceeded',
          'risk_escalated', 
          'permit_deadline_approaching',
          'task_overdue',
          'certification_expiring'
        ]
        
        user.notifications.where(notification_type: urgent_types).unread
      end

      def mark_notification_as_read(notification_id, user)
        notification = user.notifications.find(notification_id)
        notification.update(read_at: Time.current)
        notification
      end

      def bulk_mark_as_read(notification_ids, user)
        user.notifications.where(id: notification_ids).unread.update_all(read_at: Time.current)
      end

      def delete_notification(notification_id, user)
        notification = user.notifications.find(notification_id)
        notification.destroy
      end

      def bulk_delete_notifications(notification_ids, user)
        notifications_to_delete = user.notifications.where(id: notification_ids)
        count = notifications_to_delete.count
        notifications_to_delete.destroy_all
        count
      end

      # Statistiques des notifications pour un utilisateur
      def notification_stats_for_user(user)
        notifications = user.notifications
        
        {
          total: notifications.count,
          unread: notifications.unread.count,
          today: notifications.where('created_at >= ?', Date.current.beginning_of_day).count,
          this_week: notifications.where('created_at >= ?', Date.current.beginning_of_week).count,
          by_type: notifications.group(:notification_type).count,
          by_category: notifications.group(:notification_type).count, # Alias for consistency
          urgent: urgent_notifications_for_user(user).count
        }
      end
    end
end