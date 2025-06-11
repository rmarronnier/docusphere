module NotificationService::RiskNotifications
    extend ActiveSupport::Concern
    
    class_methods do
      def notify_risk_identified(risk, identified_by)
        project = risk.project
        
        # Notifier le project manager
        if project.project_manager && project.project_manager != identified_by
          Notification.notify_user(
            project.project_manager,
            :risk_identified,
            "Nouveau risque identifié",
            "#{identified_by.full_name} a identifié un nouveau risque '#{risk.title}' pour le projet '#{project.name}'",
            notifiable: risk,
            data: {
              risk_id: risk.id,
              risk_title: risk.title,
              risk_category: risk.category,
              risk_score: risk.risk_score,
              project_name: project.name,
              identified_by_id: identified_by.id
            }
          )
        end
        
        # Notifier le propriétaire du risque si assigné
        if risk.owner && risk.owner != identified_by
          Notification.notify_user(
            risk.owner,
            :risk_assigned,
            "Risque assigné",
            "Vous avez été assigné pour gérer le risque '#{risk.title}'",
            notifiable: risk,
            data: {
              risk_id: risk.id,
              risk_title: risk.title,
              risk_category: risk.category,
              project_name: project.name,
              identified_by_id: identified_by.id
            }
          )
        end
      end
      
      def notify_risk_escalated(risk, escalated_by)
        project = risk.project
        
        # Notifier le project manager si pas lui qui a escaladé
        if project.project_manager && project.project_manager != escalated_by
          Notification.notify_user(
            project.project_manager,
            :risk_escalated,
            "Risque escaladé",
            "Le risque '#{risk.title}' a été escaladé par #{escalated_by.full_name}",
            notifiable: risk,
            data: {
              risk_id: risk.id,
              risk_title: risk.title,
              risk_category: risk.category,
              risk_score: risk.risk_score,
              project_name: project.name,
              escalated_by_id: escalated_by.id
            }
          )
        end
        
        # Notifier les stakeholders de direction
        project.stakeholders.where(role: ['director', 'financial_controller']).joins(:user).each do |stakeholder|
          next if stakeholder.user == escalated_by
          
          Notification.notify_user(
            stakeholder.user,
            :risk_escalated,
            "Risque escaladé",
            "Le risque '#{risk.title}' (score: #{risk.risk_score}) nécessite votre attention",
            notifiable: risk,
            data: {
              risk_id: risk.id,
              risk_title: risk.title,
              risk_category: risk.category,
              project_name: project.name,
              stakeholder_role: stakeholder.role,
              escalated_by_id: escalated_by.id
            }
          )
        end
      end
      
      def notify_risk_mitigation_required(risk, required_by)
        project = risk.project
        
        # Notifier le propriétaire du risque
        if risk.owner && risk.owner != required_by
          Notification.notify_user(
            risk.owner,
            :risk_mitigation_required,
            "Plan d'atténuation requis",
            "Un plan d'atténuation est requis pour le risque '#{risk.title}'",
            notifiable: risk,
            data: {
              risk_id: risk.id,
              risk_title: risk.title,
              risk_category: risk.category,
              project_name: project.name,
              required_by_id: required_by.id,
              target_resolution_date: risk.target_resolution_date
            }
          )
        end
        
        # Notifier les stakeholders pertinents selon la catégorie
        relevant_roles = case risk.category
        when 'financial'
          ['financial_controller', 'project_manager']
        when 'technical'
          ['architect', 'contractor', 'project_manager']
        when 'regulatory'
          ['regulatory_expert', 'project_manager']
        else
          ['project_manager']
        end
        
        project.stakeholders.where(role: relevant_roles).joins(:user).each do |stakeholder|
          next if stakeholder.user == required_by
          
          Notification.notify_user(
            stakeholder.user,
            :risk_mitigation_required,
            "Atténuation de risque nécessaire",
            "Le risque '#{risk.title}' (#{risk.category}) nécessite un plan d'atténuation",
            notifiable: risk,
            data: {
              risk_id: risk.id,
              risk_title: risk.title,
              risk_category: risk.category,
              project_name: project.name,
              stakeholder_role: stakeholder.role
            }
          )
        end
      end
      
      def notify_risk_resolved(risk, resolved_by)
        project = risk.project
        
        # Notifier le project manager
        if project.project_manager && project.project_manager != resolved_by
          Notification.notify_user(
            project.project_manager,
            :risk_resolved,
            "Risque résolu",
            "Le risque '#{risk.title}' a été résolu par #{resolved_by.full_name}",
            notifiable: risk,
            data: {
              risk_id: risk.id,
              risk_title: risk.title,
              risk_category: risk.category,
              project_name: project.name,
              resolved_by_id: resolved_by.id,
              resolution_date: Date.current
            }
          )
        end
        
        # Notifier tous les stakeholders qui ont été impliqués
        project.stakeholders.joins(:user).each do |stakeholder|
          next if stakeholder.user == resolved_by
          
          Notification.notify_user(
            stakeholder.user,
            :risk_resolved,
            "Risque résolu",
            "Le risque '#{risk.title}' du projet '#{project.name}' a été résolu",
            notifiable: risk,
            data: {
              risk_id: risk.id,
              risk_title: risk.title,
              project_name: project.name,
              stakeholder_role: stakeholder.role,
              resolved_by_id: resolved_by.id
            }
          )
        end
      end
    end
end