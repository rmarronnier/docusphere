module NotificationService::BudgetNotifications
    extend ActiveSupport::Concern
    
    class_methods do
      def notify_budget_alert(budget, threshold_exceeded, current_percentage)
        project = budget.project
        
        # Notifier le project manager
        if project.project_manager
          Notification.notify_user(
            project.project_manager,
            :budget_alert,
            "Alerte budget",
            "Le budget '#{budget.name}' a dépassé le seuil de #{threshold_exceeded}% (actuellement #{current_percentage.round(1)}%)",
            notifiable: budget,
            data: {
              budget_id: budget.id,
              budget_name: budget.name,
              project_name: project.name,
              threshold_exceeded: threshold_exceeded,
              current_percentage: current_percentage,
              spent_amount: budget.spent_amount_cents,
              total_amount: budget.total_amount_cents
            }
          )
        end
      end
      
      def notify_budget_exceeded(budget, overage_amount)
        project = budget.project
        
        # Notifier le project manager
        if project.project_manager
          Notification.notify_user(
            project.project_manager,
            :budget_exceeded,
            "Budget dépassé",
            "Le budget '#{budget.name}' a été dépassé de #{overage_amount}€",
            notifiable: budget,
            data: {
              budget_id: budget.id,
              budget_name: budget.name,
              project_name: project.name,
              overage_amount: overage_amount,
              spent_amount: budget.spent_amount_cents,
              total_amount: budget.total_amount_cents
            }
          )
        end
        
        # Notifier les stakeholders financiers
        project.stakeholders.where(role: ['financial_controller', 'project_manager']).joins(:user).each do |stakeholder|
          Notification.notify_user(
            stakeholder.user,
            :budget_exceeded,
            "Dépassement budgétaire",
            "Le budget '#{budget.name}' a été dépassé de #{overage_amount}€",
            notifiable: budget,
            data: {
              budget_id: budget.id,
              budget_name: budget.name,
              project_name: project.name,
              stakeholder_role: stakeholder.role,
              overage_amount: overage_amount
            }
          )
        end
      end
      
      def notify_budget_adjustment_requested(budget, requested_by, new_amount)
        project = budget.project
        
        # Notifier les stakeholders qui peuvent approuver
        project.stakeholders.where(role: ['financial_controller', 'director']).joins(:user).each do |stakeholder|
          next if stakeholder.user == requested_by
          
          Notification.notify_user(
            stakeholder.user,
            :budget_adjustment_requested,
            "Ajustement budgétaire demandé",
            "#{requested_by.full_name} demande un ajustement du budget '#{budget.name}' à #{new_amount}€",
            notifiable: budget,
            data: {
              budget_id: budget.id,
              budget_name: budget.name,
              project_name: project.name,
              requested_by_id: requested_by.id,
              current_amount: budget.total_amount_cents,
              requested_amount: new_amount,
              stakeholder_role: stakeholder.role
            }
          )
        end
      end
      
      def notify_budget_adjustment_approved(budget, approved_by, new_amount)
        project = budget.project
        
        # Notifier le project manager
        if project.project_manager && project.project_manager != approved_by
          Notification.notify_user(
            project.project_manager,
            :budget_adjustment_approved,
            "Ajustement budgétaire approuvé",
            "L'ajustement du budget '#{budget.name}' à #{new_amount}€ a été approuvé",
            notifiable: budget,
            data: {
              budget_id: budget.id,
              budget_name: budget.name,
              project_name: project.name,
              approved_by_id: approved_by.id,
              previous_amount: budget.total_amount_cents,
              new_amount: new_amount
            }
          )
        end
        
        # Notifier les stakeholders concernés
        project.stakeholders.where.not(user: approved_by).joins(:user).each do |stakeholder|
          Notification.notify_user(
            stakeholder.user,
            :budget_adjustment_approved,
            "Budget mis à jour",
            "Le budget '#{budget.name}' a été ajusté à #{new_amount}€",
            notifiable: budget,
            data: {
              budget_id: budget.id,
              budget_name: budget.name,
              project_name: project.name,
              stakeholder_role: stakeholder.role,
              new_amount: new_amount
            }
          )
        end
      end
    end
end