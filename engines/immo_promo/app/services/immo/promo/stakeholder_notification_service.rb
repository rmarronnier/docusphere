module Immo
  module Promo
    class StakeholderNotificationService
      attr_reader :project, :current_user

      def initialize(project, current_user = nil)
        @project = project
        @current_user = current_user
      end

      def notify_stakeholders(message, options = {})
        stakeholders = filter_stakeholders(options)
        create_notifications(stakeholders, message, options)
      end

      def schedule_coordination_meeting(stakeholder_ids, meeting_details)
        stakeholders = project.stakeholders.where(id: stakeholder_ids)
        
        meeting_notification = build_meeting_notification(meeting_details, stakeholders)
        
        notifications = []
        stakeholders.each do |stakeholder|
          notification = create_meeting_notification(stakeholder, meeting_notification)
          notifications << notification
          send_email_notification(stakeholder, notification)
        end
        
        { meeting: meeting_notification, notifications: notifications }
      end

      private

      def filter_stakeholders(options)
        scope = project.stakeholders.active
        
        if options[:stakeholder_types]
          scope = scope.where(stakeholder_type: options[:stakeholder_types])
        end
        
        if options[:roles]
          scope = scope.where(role: options[:roles])
        end
        
        scope
      end

      def create_notifications(stakeholders, message, options)
        notifications = []
        
        stakeholders.each do |stakeholder|
          next unless stakeholder.notification_enabled
          
          notification = Notification.create!(
            user: notification_user,
            title: "Project Update",
            message: message,
            notifiable: stakeholder,
            notification_type: 'system_announcement',
            data: { 
              project_id: project.id,
              project_name: project.name
            }
          )
          
          notifications << notification
          send_email_notification(stakeholder, notification)
        end
        
        notifications
      end

      def create_meeting_notification(stakeholder, meeting_info)
        Notification.create!(
          user: notification_user,
          title: "Invitation réunion: #{meeting_info[:title]}",
          message: format_meeting_message(meeting_info),
          notifiable: stakeholder,
          notification_type: 'system_announcement',
          data: meeting_info
        )
      end

      def build_meeting_notification(details, stakeholders)
        {
          title: details[:title] || "Réunion de coordination",
          date: details[:date],
          time: details[:time],
          location: details[:location],
          agenda: details[:agenda],
          stakeholders: stakeholders.map(&:name)
        }
      end

      def format_meeting_message(meeting_info)
        message = []
        message << "Date: #{meeting_info[:date]}" if meeting_info[:date]
        message << "Heure: #{meeting_info[:time]}" if meeting_info[:time]
        message << "Lieu: #{meeting_info[:location]}" if meeting_info[:location]
        message << "Ordre du jour: #{meeting_info[:agenda]}" if meeting_info[:agenda]
        message << "Participants: #{meeting_info[:stakeholders].join(', ')}" if meeting_info[:stakeholders]
        message.join("\n")
      end

      def send_email_notification(stakeholder, notification)
        return unless stakeholder.email.present?
        
        Immo::Promo::StakeholderMailer
          .notification_email(stakeholder, notification)
          .deliver_later
      end

      def notification_user
        current_user || project.project_manager || User.first
      end
    end
  end
end