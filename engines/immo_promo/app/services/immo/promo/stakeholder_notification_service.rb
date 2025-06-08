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
        
        # Créer une seule notification globale pour la réunion
        notification = Notification.create!(
          user: notification_user,
          title: "Réunion planifiée: #{meeting_notification[:title]}",
          message: format_meeting_message(meeting_notification),
          notifiable: project,
          notification_type: 'system_announcement',
          data: meeting_notification
        )
        
        # Envoyer des emails individuels à chaque stakeholder
        stakeholders.each do |stakeholder|
          send_email_notification(stakeholder, notification)
        end
        
        { meeting: meeting_notification, notifications: [notification] }
      end
      
      def send_status_update(status_info)
        message = format_status_message(status_info)
        notify_stakeholders(message, type: :update)
      end
      
      def send_deadline_reminder(task, stakeholder)
        days_until_deadline = (task.end_date - Date.current).to_i
        message = "Rappel: La tâche '#{task.name}' est due dans #{days_until_deadline} jours"
        
        notification = Notification.create!(
          user: notification_user,
          title: "Rappel échéance",
          message: message,
          notifiable: stakeholder,
          notification_type: 'system_announcement',
          data: {
            task_id: task.id,
            task_name: task.name,
            due_date: task.end_date
          }
        )
        
        send_email_notification(stakeholder, notification)
        notification
      end
      
      def send_coordination_alerts
        alerts_sent = []
        
        # Alertes pour tâches à venir
        upcoming_tasks = project.tasks
                               .joins(:stakeholder)
                               .where('immo_promo_tasks.start_date BETWEEN ? AND ?', Date.current, 3.days.from_now)
                               .where(status: 'pending')
        
        upcoming_tasks.each do |task|
          message = "Tâche à commencer: '#{task.name}' démarre le #{task.start_date}"
          notification = notify_stakeholders(message, 
            stakeholder_types: [task.stakeholder.stakeholder_type],
            type: :alert
          )
          alerts_sent.concat(notification)
        end
        
        # Alertes pour tâches en retard
        overdue_tasks = project.tasks
                              .joins(:stakeholder)
                              .where('immo_promo_tasks.end_date < ?', Date.current)
                              .where(status: ['pending', 'in_progress'])
        
        overdue_tasks.each do |task|
          message = "Tâche en retard: '#{task.name}' devait être terminée le #{task.end_date}"
          notification = notify_stakeholders(message,
            stakeholder_types: [task.stakeholder.stakeholder_type],
            type: :alert
          )
          alerts_sent.concat(notification)
        end
        
        alerts_sent
      end

      private

      def filter_stakeholders(options)
        scope = project.stakeholders.active
        
        if options[:stakeholder_types]
          scope = scope.where(stakeholder_type: options[:stakeholder_types])
        end
        
        if options[:roles]
          if options[:roles].include?('primary')
            scope = scope.where(is_primary: true)
          end
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
            notification_type: map_notification_type(options[:type]),
            data: { 
              project_id: project.id,
              project_name: project.name
            }.merge(options[:metadata] || {})
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
      
      def format_status_message(status_info)
        message = []
        message << "Phase: #{status_info[:phase]}" if status_info[:phase]
        message << "Progression: #{status_info[:progress]}%" if status_info[:progress]
        message << "Jalons complétés: #{status_info[:milestones_completed]}" if status_info[:milestones_completed]
        message << "Prochain jalon: #{status_info[:next_milestone]}" if status_info[:next_milestone]
        message.join(" | ")
      end
      
      def map_notification_type(type)
        case type&.to_s
        when 'update', 'info', 'meeting', 'alert', 'reminder'
          'system_announcement'
        else
          'system_announcement'
        end
      end
    end
  end
end