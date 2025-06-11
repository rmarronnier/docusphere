module Immo
  module Promo
    module RiskMonitoring
      module MitigationManagement
        extend ActiveSupport::Concern

        def create_mitigation_action
          @risk = @project.risks.find(params[:risk_id])
          action_params = params.require(:action).permit(
            :action_type, :description, :responsible_id, :due_date,
            :cost_estimate, :effectiveness_estimate
          )
          
          action = @risk.mitigation_actions.build(action_params)
          action.created_by = current_user
          
          if action.save
            update_risk_mitigation_status(@risk)
            schedule_mitigation_reminders(action)
            
            flash[:success] = "Action d'atténuation créée"
          else
            flash[:error] = action.errors.full_messages.join(', ')
          end
          
          redirect_to immo_promo_engine.project_risk_monitoring_risk_register_path(@project)
        end

        private

        def update_risk_mitigation_status(risk)
          active_mitigations = risk.mitigation_actions.where(status: ['planned', 'in_progress']).count
          completed_mitigations = risk.mitigation_actions.where(status: 'completed').count
          
          if completed_mitigations > 0 && active_mitigations == 0
            risk.update(mitigation_status: 'mitigated')
          elsif active_mitigations > 0
            risk.update(mitigation_status: 'mitigation_in_progress')
          else
            risk.update(mitigation_status: 'unmitigated')
          end
        end

        def schedule_mitigation_reminders(action)
          # Planifier des rappels pour l'action d'atténuation
          if action.due_date
            ReminderService.schedule(
              action.responsible,
              action,
              action.due_date - 7.days,
              "Rappel: Action d'atténuation à venir"
            )
            
            ReminderService.schedule(
              action.responsible,
              action,
              action.due_date - 1.day,
              "Urgent: Action d'atténuation due demain"
            )
          end
        end

        def find_overdue_mitigation_actions
          MitigationAction.joins(:risk)
                         .where(risks: { project_id: @project.id })
                         .where(status: ['planned', 'in_progress'])
                         .where('due_date < ?', Date.current)
        end

        def calculate_mitigation_effectiveness
          total_mitigated = @project.risks.where(mitigation_status: 'mitigated').count
          total_with_plan = @project.risks.where.not(mitigation_status: 'unmitigated').count
          
          return 0 if total_with_plan.zero?
          
          (total_mitigated.to_f / total_with_plan * 100).round(1)
        end

        def compile_active_risks_details
          @project.risks.active.includes(:risk_owner, :mitigation_actions).map do |risk|
            {
              risk: risk,
              assessments: risk.risk_assessments.order(assessment_date: :desc).limit(3),
              mitigation_actions: risk.mitigation_actions,
              exposure: calculate_risk_exposure(risk),
              trend: analyze_risk_trend(risk)
            }
          end
        end

        def generate_risk_recommendations
          recommendations = []
          
          # Recommandations pour risques critiques
          critical_risks = @project.risks.where(severity: 'critical', status: 'active')
          if critical_risks.any?
            recommendations << {
              priority: 'urgent',
              category: 'risk_mitigation',
              recommendation: 'Développer des plans d\'atténuation immédiats pour tous les risques critiques',
              affected_risks: critical_risks.pluck(:id)
            }
          end
          
          # Recommandations pour améliorer le monitoring
          if @project.risks.count > 20 && !automated_monitoring_enabled?
            recommendations << {
              priority: 'high',
              category: 'process_improvement',
              recommendation: 'Mettre en place un système de monitoring automatisé des risques',
              benefits: ['Détection précoce', 'Alertes en temps réel', 'Réduction charge administrative']
            }
          end
          
          recommendations
        end

        def automated_monitoring_enabled?
          # Vérifier si le monitoring automatisé est activé
          AlertConfiguration.where(project: @project, active: true).exists?
        end

        def identify_key_concerns
          concerns = []
          
          # Risques critiques non atténués
          unmitigated_critical = @project.risks.where(
            severity: 'critical',
            mitigation_status: 'unmitigated'
          )
          
          if unmitigated_critical.any?
            concerns << "#{unmitigated_critical.count} risques critiques sans plan d'atténuation"
          end
          
          # Actions en retard
          overdue_actions = find_overdue_mitigation_actions
          if overdue_actions.count > 5
            concerns << "#{overdue_actions.count} actions d'atténuation en retard"
          end
          
          concerns
        end
      end
    end
  end
end