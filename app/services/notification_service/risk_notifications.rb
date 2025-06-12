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
            :risk_identified,
            "Risque assigné",
            "Vous avez été assigné pour gérer le risque '#{risk.title}'",
            notifiable: risk,
            data: {
              risk_id: risk.id,
              risk_title: risk.title,
              risk_category: risk.category,
              project_name: project.name,
              identified_by_id: identified_by.id,
              assigned: true
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
        
        # Notifier les stakeholders de type director ou financial_controller
        # Note métier: Ces stakeholders critiques devraient idéalement avoir un compte utilisateur
        # Pour l'instant, on pourrait envoyer un email si l'adresse est disponible
        # TODO: Implémenter l'envoi d'email aux stakeholders externes
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
        
        # TODO: Notifier les stakeholders pertinents quand ils auront une association user
        # Pour l'instant, on ne peut notifier que via email si disponible
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
        
        # TODO: Notifier les stakeholders quand ils auront une association user
      end
      
      def notify_risk_review_needed(project, risks_for_review, reviewer = nil)
        # Fonction métier importante : Rappel périodique de revue des risques
        # Généralement appelée par un job planifié (ex: tous les lundis)
        
        return if risks_for_review.empty?
        
        # Notifier le project manager
        if project.project_manager
          Notification.notify_user(
            project.project_manager,
            :system_announcement,  # Utiliser un type existant pour l'instant
            "Revue des risques requise",
            "#{risks_for_review.count} risques nécessitent une revue pour le projet '#{project.name}'",
            notifiable: project,
            data: {
              project_id: project.id,
              project_name: project.name,
              risk_count: risks_for_review.count,
              risk_ids: risks_for_review.map(&:id),
              review_type: 'periodic',
              due_date: Date.current + 2.days
            }
          )
        end
        
        # Notifier le responsable qualité s'il existe
        # TODO: Ajouter la notion de responsable qualité au projet
      end
    end
end