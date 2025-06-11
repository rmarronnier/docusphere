module NotificationService::PermitNotifications
    extend ActiveSupport::Concern
    
    class_methods do
      def notify_permit_submitted(permit, submitted_by)
        project = permit.project
        
        # Notifier le project manager
        if project.project_manager && project.project_manager != submitted_by
          Notification.notify_user(
            project.project_manager,
            :permit_submitted,
            "Permis soumis",
            "Le permis '#{permit.permit_type}' a été soumis pour le projet '#{project.name}'",
            notifiable: permit,
            data: {
              permit_id: permit.id,
              permit_type: permit.permit_type,
              project_id: project.id,
              project_name: project.name,
              submitted_by_id: submitted_by.id,
              submitted_date: permit.submitted_date
            }
          )
        end
      end
      
      def notify_permit_approved(permit)
        project = permit.project
        
        # Notifier le project manager
        if project.project_manager
          Notification.notify_user(
            project.project_manager,
            :permit_approved,
            "Permis approuvé",
            "Le permis '#{permit.permit_type}' du projet '#{project.name}' a été approuvé",
            notifiable: permit,
            data: {
              permit_id: permit.id,
              permit_type: permit.permit_type,
              project_id: project.id,
              project_name: project.name,
              approval_date: permit.approval_date,
              expiry_date: permit.expiry_date
            }
          )
        end
        
        # Notifier les stakeholders concernés
        project.stakeholders.where(role: ['architect', 'contractor']).joins(:user).each do |stakeholder|
          Notification.notify_user(
            stakeholder.user,
            :permit_approved,
            "Permis approuvé",
            "Le permis '#{permit.permit_type}' a été approuvé pour le projet '#{project.name}'",
            notifiable: permit,
            data: {
              permit_id: permit.id,
              permit_type: permit.permit_type,
              project_name: project.name,
              stakeholder_role: stakeholder.role
            }
          )
        end
      end
      
      def notify_permit_rejected(permit, reason = nil)
        project = permit.project
        
        message = "Le permis '#{permit.permit_type}' du projet '#{project.name}' a été rejeté"
        message += " : #{reason}" if reason.present?
        
        # Notifier le project manager
        if project.project_manager
          Notification.notify_user(
            project.project_manager,
            :permit_rejected,
            "Permis rejeté",
            message,
            notifiable: permit,
            data: {
              permit_id: permit.id,
              permit_type: permit.permit_type,
              project_id: project.id,
              project_name: project.name,
              rejection_reason: reason
            }
          )
        end
      end
      
      def notify_permit_deadline_approaching(permit, days_remaining)
        project = permit.project
        
        # Notifier le project manager
        if project.project_manager
          Notification.notify_user(
            project.project_manager,
            :permit_deadline_approaching,
            "Échéance permis proche",
            "Le permis '#{permit.permit_type}' arrive à échéance dans #{days_remaining} jours",
            notifiable: permit,
            data: {
              permit_id: permit.id,
              permit_type: permit.permit_type,
              project_name: project.name,
              expiry_date: permit.expiry_date,
              days_remaining: days_remaining
            }
          )
        end
        
        # Notifier les stakeholders responsables
        project.stakeholders.where(role: ['architect', 'project_manager']).joins(:user).each do |stakeholder|
          Notification.notify_user(
            stakeholder.user,
            :permit_deadline_approaching,
            "Échéance permis proche",
            "Le permis '#{permit.permit_type}' expire dans #{days_remaining} jours",
            notifiable: permit,
            data: {
              permit_id: permit.id,
              permit_type: permit.permit_type,
              project_name: project.name,
              stakeholder_role: stakeholder.role,
              days_remaining: days_remaining
            }
          )
        end
      end
      
      def notify_permit_condition_fulfilled(condition, permit)
        project = permit.project
        
        # Notifier le project manager
        if project.project_manager
          Notification.notify_user(
            project.project_manager,
            :permit_condition_fulfilled,
            "Condition de permis remplie",
            "Une condition du permis '#{permit.permit_type}' a été remplie",
            notifiable: condition,
            data: {
              condition_id: condition.id,
              permit_id: permit.id,
              permit_type: permit.permit_type,
              project_name: project.name,
              condition_description: condition.description,
              compliance_date: condition.compliance_date
            }
          )
        end
      end
    end
end