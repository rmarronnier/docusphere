module Immo
  module Promo
    module RiskMonitoring
      module RiskManagement
        extend ActiveSupport::Concern

        def create_risk
          risk_params = params.require(:risk).permit(
            :title, :description, :category, :probability, :impact,
            :risk_owner_id, :detection_date, :target_resolution_date
          )
          
          @risk = @project.risks.build(risk_params)
          @risk.identified_by = current_user
          @risk.status = 'identified'
          
          if @risk.save
            calculate_risk_score(@risk)
            create_initial_assessment(@risk)
            notify_risk_stakeholders(@risk)
            
            flash[:success] = "Risque identifié et enregistré"
            redirect_to immo_promo_engine.project_risk_monitoring_risk_register_path(@project)
          else
            flash[:error] = @risk.errors.full_messages.join(', ')
            redirect_back(fallback_location: immo_promo_engine.project_risk_monitoring_dashboard_path(@project))
          end
        end

        def risk_register
          @risks = @project.risks.includes(:mitigation_actions, :risk_assessments)
          @filters = params[:filters] || {}
          
          apply_risk_filters if @filters.any?
          
          @risks_by_category = @risks.group_by(&:category)
          @risks_by_severity = @risks.group_by(&:severity)
          @risks_by_status = @risks.group_by(&:status)
        end

        private

        def apply_risk_filters
          @risks = @risks.where(category: @filters[:category]) if @filters[:category].present?
          @risks = @risks.where(severity: @filters[:severity]) if @filters[:severity].present?
          @risks = @risks.where(status: @filters[:status]) if @filters[:status].present?
          @risks = @risks.where(risk_owner_id: @filters[:owner]) if @filters[:owner].present?
          
          if @filters[:probability].present?
            @risks = @risks.where(probability: @filters[:probability])
          end
          
          if @filters[:impact].present?
            @risks = @risks.where(impact: @filters[:impact])
          end
        end

        def calculate_risk_score(risk)
          probability_scores = { 'very_low' => 1, 'low' => 2, 'medium' => 3, 'high' => 4, 'very_high' => 5 }
          impact_scores = { 'negligible' => 1, 'minor' => 2, 'moderate' => 3, 'major' => 4, 'catastrophic' => 5 }
          
          prob_score = probability_scores[risk.probability] || 3
          impact_score = impact_scores[risk.impact] || 3
          
          risk.risk_score = prob_score * impact_score
          risk.severity = determine_severity(risk.risk_score)
          risk.save
        end

        def determine_severity(score)
          case score
          when 1..6
            'low'
          when 7..12
            'medium'
          when 13..19
            'high'
          else
            'critical'
          end
        end

        def create_initial_assessment(risk)
          assessment = risk.risk_assessments.create(
            assessed_by: current_user,
            probability: risk.probability,
            impact: risk.impact,
            assessment_date: Date.current,
            notes: "Évaluation initiale"
          )
        end

        def notify_risk_stakeholders(risk)
          stakeholders = identify_risk_stakeholders(risk)
          
          stakeholders.each do |stakeholder|
            RiskNotificationService.notify(
              stakeholder,
              "Nouveau risque identifié: #{risk.title}",
              risk
            )
          end
        end

        def identify_risk_stakeholders(risk)
          stakeholders = [risk.risk_owner]
          stakeholders << @project.project_manager
          
          # Ajouter les parties prenantes selon la catégorie du risque
          case risk.category
          when 'financial'
            stakeholders << @project.financial_controller
          when 'technical'
            stakeholders << @project.technical_manager
          when 'regulatory'
            stakeholders << @project.compliance_officer
          end
          
          stakeholders.compact.uniq
        end

        def detect_emerging_risks
          # Détection des risques émergents basée sur les indicateurs
          emerging = []
          
          # Exemple: Risques liés aux retards
          if project_delay_risk?
            emerging << {
              type: 'schedule_risk',
              title: 'Risque de retard projet',
              indicators: ['Retard sur jalons critiques', 'Tâches en retard > 15%'],
              recommended_action: 'Réviser le planning et identifier les causes'
            }
          end
          
          # Exemple: Risques budgétaires
          if budget_overrun_risk?
            emerging << {
              type: 'budget_risk',
              title: 'Risque de dépassement budgétaire',
              indicators: ['Consommation > 90% avec 70% d\'avancement', 'Tendance défavorable'],
              recommended_action: 'Analyser les écarts et mettre en place des mesures de contrôle'
            }
          end
          
          emerging
        end

        def project_delay_risk?
          # Logique simplifiée de détection de risque de retard
          overdue_tasks = @project.tasks.where('due_date < ? AND status != ?', Date.current, 'completed').count
          total_tasks = @project.tasks.count
          
          return false if total_tasks.zero?
          
          (overdue_tasks.to_f / total_tasks) > 0.15
        end

        def budget_overrun_risk?
          # Logique simplifiée de détection de risque budgétaire
          return false unless @project.total_budget && @project.current_budget
          
          budget_usage = @project.budget_usage_percentage
          project_progress = @project.calculate_overall_progress
          
          budget_usage > 90 && project_progress < 70
        end
      end
    end
  end
end