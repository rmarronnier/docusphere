module Immo
  module Promo
    module RiskAlertable
      extend ActiveSupport::Concern

      private

      def setup_risk_alerts(risks)
        alerts = []
        
        # Alertes pour risques critiques
        critical_risks = risks.select { |r| r[:severity] == 'critical' || r[:probability] == 'very_high' }
        critical_risks.each do |risk|
          alerts << create_risk_alert(risk, :critical)
        end
        
        # Alertes pour risques avec actions en retard
        overdue_risks = risks.select { |r| has_overdue_actions?(r) }
        overdue_risks.each do |risk|
          alerts << create_overdue_alert(risk)
        end
        
        # Alertes pour risques émergents
        emerging_risks = detect_emerging_risks_for_project
        emerging_risks.each do |risk|
          alerts << create_emerging_alert(risk)
        end
        
        alerts
      end

      def create_risk_alert(risk, level = :normal)
        {
          id: SecureRandom.uuid,
          risk_id: risk[:id],
          type: 'risk_alert',
          level: level,
          title: alert_title_for_risk(risk, level),
          message: alert_message_for_risk(risk, level),
          created_at: Time.current,
          actions: suggest_alert_actions(risk, level)
        }
      end

      def create_overdue_alert(risk)
        overdue_actions = risk[:mitigation_actions]&.select { |a| a[:due_date] && a[:due_date] < Date.current }
        
        {
          id: SecureRandom.uuid,
          risk_id: risk[:id],
          type: 'overdue_actions',
          level: :warning,
          title: "Actions en retard pour: #{risk[:title]}",
          message: "#{overdue_actions.count} action(s) d'atténuation en retard",
          created_at: Time.current,
          overdue_count: overdue_actions.count,
          oldest_overdue: overdue_actions.min_by { |a| a[:due_date] }&.dig(:due_date)
        }
      end

      def create_emerging_alert(risk)
        {
          id: SecureRandom.uuid,
          type: 'emerging_risk',
          level: :info,
          title: risk[:title],
          message: "Risque émergent détecté: #{risk[:indicators].join(', ')}",
          created_at: Time.current,
          recommended_action: risk[:recommended_action],
          indicators: risk[:indicators]
        }
      end

      def alert_title_for_risk(risk, level)
        case level
        when :critical
          "⚠️ ALERTE CRITIQUE: #{risk[:title]}"
        when :warning
          "⚠️ Attention requise: #{risk[:title]}"
        else
          "ℹ️ Information: #{risk[:title]}"
        end
      end

      def alert_message_for_risk(risk, level)
        base_message = risk[:description] || risk[:title]
        
        case level
        when :critical
          "Action immédiate requise. #{base_message}. Impact: #{risk[:impact]}. Probabilité: #{risk[:probability]}."
        when :warning
          "Surveillance accrue nécessaire. #{base_message}"
        else
          base_message
        end
      end

      def suggest_alert_actions(risk, level)
        actions = []
        
        case level
        when :critical
          actions << {
            label: 'Convoquer réunion de crise',
            action: 'schedule_crisis_meeting',
            urgency: 'immediate'
          }
          actions << {
            label: 'Notifier la direction',
            action: 'notify_management',
            urgency: 'immediate'
          }
        when :warning
          actions << {
            label: 'Planifier révision',
            action: 'schedule_review',
            urgency: 'high'
          }
        end
        
        actions << {
          label: 'Voir détails du risque',
          action: 'view_risk_details',
          urgency: 'normal'
        }
        
        actions
      end

      def has_overdue_actions?(risk)
        return false unless risk[:mitigation_actions]
        
        risk[:mitigation_actions].any? do |action|
          action[:status] != 'completed' && 
          action[:due_date] && 
          action[:due_date] < Date.current
        end
      end

      def detect_emerging_risks_for_project
        emerging = []
        
        # Risques liés aux retards
        if project_has_schedule_risks?
          emerging << {
            type: 'schedule_risk',
            title: 'Risque de retard projet',
            indicators: identify_schedule_risk_indicators,
            recommended_action: 'Réviser le planning et identifier les causes'
          }
        end
        
        # Risques budgétaires
        if project_has_budget_risks?
          emerging << {
            type: 'budget_risk',
            title: 'Risque de dépassement budgétaire',
            indicators: identify_budget_risk_indicators,
            recommended_action: 'Analyser les postes de dépassement'
          }
        end
        
        # Risques de qualité
        if project_has_quality_risks?
          emerging << {
            type: 'quality_risk',
            title: 'Risque de non-conformité',
            indicators: identify_quality_risk_indicators,
            recommended_action: 'Renforcer les contrôles qualité'
          }
        end
        
        emerging
      end

      def project_has_schedule_risks?
        return false unless @project
        
        # Logique simplifiée - vérifierait les jalons, tâches en retard, etc.
        @project.phases.any?(&:is_delayed?) ||
        (@project.tasks.where(status: 'overdue').count.to_f / @project.tasks.count > 0.15)
      rescue
        false
      end

      def project_has_budget_risks?
        return false unless @project
        
        # Logique simplifiée - vérifierait le budget consommé vs planifié
        @project.budget_usage_percentage > 90 && @project.completion_percentage < 80
      rescue
        false
      end

      def project_has_quality_risks?
        return false unless @project
        
        # Logique simplifiée - vérifierait les non-conformités, retours, etc.
        false # À implémenter selon les besoins
      end

      def identify_schedule_risk_indicators
        indicators = []
        
        if @project&.phases&.any?(&:is_delayed?)
          indicators << "Phases en retard détectées"
        end
        
        overdue_tasks = @project&.tasks&.where(status: 'overdue')&.count || 0
        if overdue_tasks > 0
          indicators << "#{overdue_tasks} tâches en retard"
        end
        
        indicators << "Jalons critiques menacés" if critical_milestones_at_risk?
        
        indicators
      end

      def identify_budget_risk_indicators
        indicators = []
        
        if @project&.budget_usage_percentage
          indicators << "Budget consommé à #{@project.budget_usage_percentage}%"
        end
        
        if @project&.is_over_budget?
          indicators << "Dépassement budgétaire confirmé"
        end
        
        indicators
      end

      def identify_quality_risk_indicators
        # À implémenter selon les besoins du projet
        []
      end

      def critical_milestones_at_risk?
        return false unless @project
        
        @project.milestones.where(is_critical: true).any? do |milestone|
          milestone.target_date && 
          milestone.status != 'completed' && 
          (milestone.target_date - Date.current).days < 7
        end
      rescue
        false
      end

      def schedule_risk_notifications(alerts)
        alerts.each do |alert|
          next unless should_send_notification?(alert)
          
          recipients = determine_alert_recipients(alert)
          recipients.each do |recipient|
            NotificationService.send_risk_alert(
              recipient,
              alert,
              @project
            )
          end
          
          # Marquer l'alerte comme envoyée
          mark_alert_as_sent(alert)
        end
      end

      def should_send_notification?(alert)
        case alert[:level]
        when :critical
          true # Toujours envoyer les alertes critiques
        when :warning
          !alert_recently_sent?(alert, 1.day)
        else
          !alert_recently_sent?(alert, 3.days)
        end
      end

      def alert_recently_sent?(alert, period)
        # Vérifier si une alerte similaire a été envoyée récemment
        # Implémentation simplifiée
        false
      end

      def determine_alert_recipients(alert)
        recipients = []
        
        case alert[:level]
        when :critical
          recipients << @project.project_manager if @project.project_manager
          recipients += @project.stakeholders.where(role: ['director', 'manager']).map(&:user)
        when :warning
          recipients << @project.project_manager if @project.project_manager
          recipients += find_risk_owners_for_alert(alert)
        else
          recipients += find_risk_owners_for_alert(alert)
        end
        
        recipients.compact.uniq
      end

      def find_risk_owners_for_alert(alert)
        return [] unless alert[:risk_id]
        
        # Trouver les responsables du risque
        risk = @project.risks.find_by(id: alert[:risk_id])
        return [] unless risk
        
        owners = []
        owners << risk.owner if risk.respond_to?(:owner)
        owners += risk.mitigation_actions.map(&:responsible).compact if risk.respond_to?(:mitigation_actions)
        
        owners.uniq
      end

      def mark_alert_as_sent(alert)
        # Enregistrer que l'alerte a été envoyée
        # Implémentation selon le système de persistance des alertes
      end
    end
  end
end