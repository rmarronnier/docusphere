module Immo
  module Promo
    module FinancialDashboard
      module BudgetAdjustments
        extend ActiveSupport::Concern

        def approve_budget_adjustment
          @budget = @project.budgets.find(params[:budget_id])
          adjustment_params = params.require(:adjustment).permit(:amount, :category, :justification, :approval_level)
          
          adjustment = create_budget_adjustment(@budget, adjustment_params)
          
          if adjustment[:success]
            log_budget_adjustment(adjustment[:record], current_user)
            flash[:success] = "Ajustement budgétaire approuvé"
            
            # Notifier les parties prenantes si l'ajustement est significatif
            if significant_adjustment?(adjustment[:record])
              send_budget_adjustment_notifications(adjustment[:record])
            end
          else
            flash[:error] = adjustment[:error]
          end
          
          redirect_to immo_promo_engine.project_financial_dashboard_path(@project)
        end

        def reallocate_budget
          reallocation_params = params.require(:reallocation).permit(
            :from_budget_id, :to_budget_id, :amount, :justification
          )
          
          result = execute_budget_reallocation(reallocation_params)
          
          if result[:success]
            flash[:success] = "Réallocation budgétaire effectuée"
            log_budget_reallocation(result[:reallocation], current_user)
          else
            flash[:error] = result[:error]
          end
          
          redirect_back(fallback_location: immo_promo_engine.project_financial_dashboard_variance_analysis_path(@project))
        end

        def set_budget_alert
          alert_params = params.require(:alert).permit(:threshold_type, :threshold_value, :notification_method)
          
          alert = create_budget_alert(alert_params)
          
          if alert[:success]
            flash[:success] = "Alerte budgétaire configurée"
          else
            flash[:error] = alert[:error]
          end
          
          redirect_back(fallback_location: immo_promo_engine.project_financial_dashboard_path(@project))
        end

        private

        def create_budget_adjustment(budget, params)
          # Validation des autorisations
          unless authorized_for_adjustment?(params[:approval_level])
            return { success: false, error: "Autorisation insuffisante pour cet ajustement" }
          end

          # Validation des montants
          unless valid_adjustment_amount?(budget, params[:amount])
            return { success: false, error: "Montant d'ajustement invalide" }
          end

          # Créer l'ajustement
          adjustment = budget.budget_adjustments.build(
            amount: params[:amount],
            category: params[:category],
            justification: params[:justification],
            approval_level: params[:approval_level],
            requested_by: current_user,
            approved_by: current_user,
            approved_at: Time.current,
            status: 'approved'
          )

          if adjustment.save
            # Mettre à jour le budget
            update_budget_after_adjustment(budget, adjustment)
            
            # Recalculer les métriques du projet
            recalculate_project_metrics(budget.project)
            
            { success: true, record: adjustment }
          else
            { success: false, error: adjustment.errors.full_messages.join(', ') }
          end
        end

        def execute_budget_reallocation(params)
          from_budget = @project.budgets.find(params[:from_budget_id])
          to_budget = @project.budgets.find(params[:to_budget_id])
          amount = params[:amount].to_f

          # Validations
          unless sufficient_budget_available?(from_budget, amount)
            return { success: false, error: "Budget source insuffisant" }
          end

          unless valid_reallocation_target?(to_budget, amount)
            return { success: false, error: "Budget cible invalide pour cette réallocation" }
          end

          # Effectuer la réallocation dans une transaction
          reallocation = nil
          
          ActiveRecord::Base.transaction do
            # Créer l'enregistrement de réallocation
            reallocation = create_reallocation_record(from_budget, to_budget, amount, params[:justification])
            
            # Ajuster les budgets
            adjust_budget_amounts(from_budget, to_budget, amount)
            
            # Mettre à jour les allocations
            update_budget_allocations(from_budget, to_budget, amount)
            
            # Recalculer les métriques
            recalculate_affected_metrics([from_budget, to_budget])
          end

          { success: true, reallocation: reallocation }
        rescue StandardError => e
          { success: false, error: "Erreur lors de la réallocation: #{e.message}" }
        end

        def create_budget_alert(params)
          # Valider les paramètres
          unless valid_alert_threshold?(params[:threshold_type], params[:threshold_value])
            return { success: false, error: "Seuil d'alerte invalide" }
          end

          alert = @project.budget_alerts.build(
            threshold_type: params[:threshold_type],
            threshold_value: params[:threshold_value],
            notification_method: params[:notification_method],
            created_by: current_user,
            active: true
          )

          if alert.save
            # Configurer les notifications automatiques
            setup_alert_notifications(alert)
            
            { success: true, record: alert }
          else
            { success: false, error: alert.errors.full_messages.join(', ') }
          end
        end

        def significant_adjustment?(adjustment)
          budget = adjustment.budget
          adjustment_percent = (adjustment.amount.abs / budget.total_amount.to_f * 100)
          
          # Considéré comme significatif si > 5% du budget total ou > 50k€
          adjustment_percent > 5 || adjustment.amount.abs > 50000
        end

        def send_budget_adjustment_notifications(adjustment)
          # Identifier les parties prenantes à notifier
          stakeholders = identify_adjustment_stakeholders(adjustment)
          
          stakeholders.each do |stakeholder|
            notification_content = build_adjustment_notification(adjustment, stakeholder)
            send_adjustment_notification(stakeholder, notification_content)
          end
        end

        def log_budget_adjustment(adjustment, user)
          Rails.logger.info "BUDGET_ADJUSTMENT: #{adjustment.id} by user #{user.id} - Amount: #{adjustment.amount}"
          
          # Créer un audit trail
          create_audit_trail_entry({
            action: 'budget_adjustment',
            resource: adjustment,
            user: user,
            details: {
              amount: adjustment.amount,
              category: adjustment.category,
              justification: adjustment.justification
            }
          })
        end

        def log_budget_reallocation(reallocation, user)
          Rails.logger.info "BUDGET_REALLOCATION: #{reallocation.id} by user #{user.id} - Amount: #{reallocation.amount}"
          
          create_audit_trail_entry({
            action: 'budget_reallocation',
            resource: reallocation,
            user: user,
            details: {
              from_budget: reallocation.from_budget.name,
              to_budget: reallocation.to_budget.name,
              amount: reallocation.amount
            }
          })
        end

        # Méthodes de validation

        def authorized_for_adjustment?(approval_level)
          case approval_level
          when 'minor'
            current_user.can?(:manage_budget_minor_adjustments, @project)
          when 'major'
            current_user.can?(:manage_budget_major_adjustments, @project)
          when 'critical'
            current_user.can?(:manage_budget_critical_adjustments, @project)
          else
            false
          end
        end

        def valid_adjustment_amount?(budget, amount)
          amount_f = amount.to_f
          
          # Vérifications de base
          return false if amount_f.zero?
          return false if amount_f.abs > budget.total_amount * 0.5 # Max 50% du budget
          
          # Vérifications selon le type d'ajustement
          if amount_f > 0 # Augmentation
            return budget.can_increase_by?(amount_f)
          else # Diminution
            return budget.can_decrease_by?(amount_f.abs)
          end
        end

        def sufficient_budget_available?(budget, amount)
          available_amount = budget.available_amount
          amount > 0 && amount <= available_amount
        end

        def valid_reallocation_target?(budget, amount)
          # Vérifier que le budget cible peut accepter cette allocation
          budget.can_receive_reallocation?(amount)
        end

        def valid_alert_threshold?(threshold_type, threshold_value)
          case threshold_type
          when 'percentage'
            threshold_value.to_f.between?(1, 100)
          when 'absolute'
            threshold_value.to_f > 0
          when 'variance'
            threshold_value.to_f.between?(1, 50)
          else
            false
          end
        end

        # Méthodes de mise à jour

        def update_budget_after_adjustment(budget, adjustment)
          if adjustment.amount > 0
            budget.increment!(:allocated_amount, adjustment.amount)
          else
            budget.decrement!(:allocated_amount, adjustment.amount.abs)
          end
          
          # Mettre à jour le timestamp de dernière modification
          budget.touch(:last_modified_at)
        end

        def adjust_budget_amounts(from_budget, to_budget, amount)
          from_budget.decrement!(:available_amount, amount)
          to_budget.increment!(:available_amount, amount)
          
          # Mettre à jour les timestamps
          [from_budget, to_budget].each { |b| b.touch(:last_modified_at) }
        end

        def update_budget_allocations(from_budget, to_budget, amount)
          # Créer les lignes d'allocation pour traçabilité
          from_budget.allocation_lines.create!(
            amount: -amount,
            description: "Réallocation vers #{to_budget.name}",
            transaction_type: 'reallocation_out'
          )
          
          to_budget.allocation_lines.create!(
            amount: amount,
            description: "Réallocation depuis #{from_budget.name}",
            transaction_type: 'reallocation_in'
          )
        end

        def recalculate_project_metrics(project)
          # Recalculer les métriques financières du projet
          budget_service = Immo::Promo::ProjectBudgetService.new(project)
          budget_service.recalculate_all_metrics
        end

        def recalculate_affected_metrics(budgets)
          budgets.each do |budget|
            budget.recalculate_metrics
          end
          
          # Recalculer les métriques du projet parent
          recalculate_project_metrics(@project)
        end

        # Méthodes utilitaires

        def create_reallocation_record(from_budget, to_budget, amount, justification)
          @project.budget_reallocations.create!(
            from_budget: from_budget,
            to_budget: to_budget,
            amount: amount,
            justification: justification,
            executed_by: current_user,
            executed_at: Time.current,
            status: 'completed'
          )
        end

        def setup_alert_notifications(alert)
          # Configurer les tâches de vérification périodique
          case alert.threshold_type
          when 'percentage', 'variance'
            schedule_periodic_check(alert, 'daily')
          when 'absolute'
            schedule_immediate_check(alert)
          end
        end

        def identify_adjustment_stakeholders(adjustment)
          stakeholders = []
          
          # Toujours notifier le chef de projet
          stakeholders << @project.project_manager if @project.project_manager
          
          # Notifier le directeur financier si ajustement significatif
          if significant_adjustment?(adjustment)
            stakeholders << find_financial_director
          end
          
          # Notifier les utilisateurs avec permissions budgétaires
          stakeholders.concat(find_budget_managers)
          
          stakeholders.compact.uniq
        end

        def create_audit_trail_entry(details)
          @project.audit_trails.create!(
            action: details[:action],
            resource_type: details[:resource].class.name,
            resource_id: details[:resource].id,
            user: details[:user],
            details: details[:details],
            timestamp: Time.current
          )
        end
      end
    end
  end
end