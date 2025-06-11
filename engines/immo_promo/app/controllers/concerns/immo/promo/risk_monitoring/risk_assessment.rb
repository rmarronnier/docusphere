module Immo
  module Promo
    module RiskMonitoring
      module RiskAssessment
        extend ActiveSupport::Concern

        def update_risk_assessment
          @risk = @project.risks.find(params[:risk_id])
          assessment_params = params.require(:assessment).permit(
            :probability, :impact, :notes, :reassessment_reason
          )
          
          assessment = create_risk_assessment(@risk, assessment_params)
          
          if assessment[:success]
            update_risk_score(@risk)
            check_risk_escalation(@risk)
            
            flash[:success] = "Évaluation du risque mise à jour"
          else
            flash[:error] = assessment[:error]
          end
          
          redirect_back(fallback_location: immo_promo_engine.project_risk_monitoring_risk_register_path(@project))
        end

        private

        def create_risk_assessment(risk, params)
          assessment = risk.risk_assessments.build(
            assessed_by: current_user,
            probability: params[:probability],
            impact: params[:impact],
            assessment_date: Date.current,
            notes: params[:notes],
            reassessment_reason: params[:reassessment_reason]
          )
          
          if assessment.save
            { success: true, assessment: assessment }
          else
            { success: false, error: assessment.errors.full_messages.join(', ') }
          end
        end

        def update_risk_score(risk)
          probability_scores = { 'very_low' => 1, 'low' => 2, 'medium' => 3, 'high' => 4, 'very_high' => 5 }
          impact_scores = { 'negligible' => 1, 'minor' => 2, 'moderate' => 3, 'major' => 4, 'catastrophic' => 5 }
          
          prob_score = probability_scores[risk.probability] || 3
          impact_score = impact_scores[risk.impact] || 3
          
          risk.risk_score = prob_score * impact_score
          risk.severity = determine_severity_from_score(risk.risk_score)
          risk.save
        end

        def determine_severity_from_score(score)
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

        def check_risk_escalation(risk)
          previous_severity = risk.severity_was
          
          if risk.severity != previous_severity && ['high', 'critical'].include?(risk.severity)
            escalate_risk(risk, previous_severity)
          end
        end

        def escalate_risk(risk, previous_severity)
          # Notifier la hiérarchie
          escalation_recipients = determine_escalation_recipients(risk)
          
          escalation_recipients.each do |recipient|
            RiskNotificationService.escalate(
              recipient,
              "Escalade risque: #{risk.title}",
              risk,
              previous_severity
            )
          end
          
          # Créer une entrée d'escalade
          risk.escalations.create(
            escalated_by: current_user,
            escalated_at: Time.current,
            from_severity: previous_severity,
            to_severity: risk.severity,
            reason: "Réévaluation du risque"
          )
        end

        def determine_escalation_recipients(risk)
          recipients = [@project.project_manager]
          
          if risk.severity == 'critical'
            recipients << @project.sponsor
            recipients << @project.executive_committee
          end
          
          recipients.flatten.compact.uniq
        end

        def calculate_risk_exposure(risk)
          # Calcul de l'exposition au risque (impact financier potentiel)
          base_exposure = case risk.impact
          when 'catastrophic' then 1_000_000
          when 'major' then 500_000
          when 'moderate' then 100_000
          when 'minor' then 25_000
          else 5_000
          end
          
          probability_factor = case risk.probability
          when 'very_high' then 0.9
          when 'high' then 0.7
          when 'medium' then 0.5
          when 'low' then 0.3
          else 0.1
          end
          
          Money.new((base_exposure * probability_factor).to_i, 'EUR')
        end

        def analyze_risk_trend(risk)
          recent_assessments = risk.risk_assessments.order(assessment_date: :desc).limit(3)
          
          return 'stable' if recent_assessments.count < 2
          
          scores = recent_assessments.map { |a| calculate_assessment_score(a) }
          
          if scores.first > scores.last
            'increasing'
          elsif scores.first < scores.last
            'decreasing'
          else
            'stable'
          end
        end

        def calculate_assessment_score(assessment)
          probability_scores = { 'very_low' => 1, 'low' => 2, 'medium' => 3, 'high' => 4, 'very_high' => 5 }
          impact_scores = { 'negligible' => 1, 'minor' => 2, 'moderate' => 3, 'major' => 4, 'catastrophic' => 5 }
          
          prob_score = probability_scores[assessment.probability] || 3
          impact_score = impact_scores[assessment.impact] || 3
          
          prob_score * impact_score
        end
      end
    end
  end
end