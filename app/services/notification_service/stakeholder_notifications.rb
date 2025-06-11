module NotificationService::StakeholderNotifications
    extend ActiveSupport::Concern
    
    class_methods do
      def notify_stakeholder_assigned(stakeholder, project, assigned_by)
        if stakeholder.user && stakeholder.user != assigned_by
          Notification.notify_user(
            stakeholder.user,
            :stakeholder_assigned,
            "Assigné comme intervenant",
            "#{assigned_by.full_name} vous a assigné comme #{stakeholder.role} sur le projet '#{project.name}'",
            notifiable: stakeholder,
            data: {
              stakeholder_id: stakeholder.id,
              project_id: project.id,
              project_name: project.name,
              role: stakeholder.role,
              assigned_by_id: assigned_by.id
            }
          )
        end
      end
      
      def notify_stakeholder_approved(stakeholder, approved_by)
        if stakeholder.user
          Notification.notify_user(
            stakeholder.user,
            :stakeholder_approved,
            "Validation approuvée",
            "Votre qualification comme #{stakeholder.role} a été approuvée par #{approved_by.full_name}",
            notifiable: stakeholder,
            data: {
              stakeholder_id: stakeholder.id,
              project_name: stakeholder.project.name,
              role: stakeholder.role,
              approved_by_id: approved_by.id
            }
          )
        end
      end
      
      def notify_stakeholder_rejected(stakeholder, rejected_by, reason = nil)
        if stakeholder.user
          message = "Votre qualification comme #{stakeholder.role} a été rejetée"
          message += " : #{reason}" if reason.present?
          
          Notification.notify_user(
            stakeholder.user,
            :stakeholder_rejected,
            "Qualification rejetée",
            message,
            notifiable: stakeholder,
            data: {
              stakeholder_id: stakeholder.id,
              project_name: stakeholder.project.name,
              role: stakeholder.role,
              rejected_by_id: rejected_by.id,
              rejection_reason: reason
            }
          )
        end
      end
      
      def notify_stakeholder_certification_expiring(stakeholder, days_remaining)
        if stakeholder.user
          Notification.notify_user(
            stakeholder.user,
            :certification_expiring,
            "Certification expire bientôt",
            "Votre certification expire dans #{days_remaining} jours. Veuillez la renouveler.",
            notifiable: stakeholder,
            data: {
              stakeholder_id: stakeholder.id,
              project_name: stakeholder.project.name,
              certification_type: stakeholder.certifications.first&.name,
              days_remaining: days_remaining,
              expiry_date: stakeholder.certifications.first&.expiry_date
            }
          )
        end
      end
    end
end