module Immo
  module Promo
    class PermitDeadlineService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def track_permit_deadlines
        deadline_alerts = []
        
        project.permits.each do |permit|
          deadline_alerts.concat(check_submission_deadlines(permit))
          deadline_alerts.concat(check_response_deadlines(permit))
          deadline_alerts.concat(check_expiry_deadlines(permit))
          deadline_alerts.concat(check_condition_deadlines(permit))
        end
        
        deadline_alerts.sort_by { |alert| urgency_score(alert[:urgency]) }.reverse
      end

      def critical_deadlines
        track_permit_deadlines.select { |alert| alert[:urgency] == :critical }
      end

      def upcoming_deadlines(days = 30)
        cutoff_date = Date.current + days.days
        
        deadlines = []
        
        # Check permit expirations
        project.permits.approved.each do |permit|
          if permit.expiry_date && permit.expiry_date <= cutoff_date
            deadlines << build_deadline(
              permit,
              permit.expiry_date,
              :expiry,
              "Expiration du #{permit.permit_type.humanize}"
            )
          end
        end
        
        # Check condition deadlines
        project.permits.each do |permit|
          permit.permit_conditions.where(is_fulfilled: false).each do |condition|
            if condition.due_date && condition.due_date <= cutoff_date
              deadlines << build_deadline(
                condition,
                condition.due_date,
                :condition,
                "Condition à remplir : #{condition.description}"
              )
            end
          end
        end
        
        deadlines.sort_by { |d| d[:date] }
      end

      def overdue_items
        overdue = []
        
        # Overdue permit responses
        project.permits.under_review.each do |permit|
          if permit.overdue_days && permit.overdue_days > 0
            overdue << {
              item: permit,
              type: :permit_response,
              overdue_days: permit.overdue_days,
              message: "Réponse #{permit.permit_type.humanize} en retard de #{permit.overdue_days} jours"
            }
          end
        end
        
        # Overdue conditions
        PermitCondition.joins(:permit)
                      .where(permit: project.permits)
                      .where(is_fulfilled: false)
                      .where('due_date < ?', Date.current)
                      .each do |condition|
          overdue_days = (Date.current - condition.due_date).to_i
          overdue << {
            item: condition,
            type: :condition,
            overdue_days: overdue_days,
            message: "Condition en retard : #{condition.description}"
          }
        end
        
        overdue.sort_by { |item| -item[:overdue_days] }
      end

      def generate_deadline_calendar
        calendar_events = []
        
        project.permits.each do |permit|
          # Submission deadlines
          if permit.draft?
            submission_deadline = calculate_submission_deadline(permit)
            if submission_deadline
              calendar_events << {
                date: submission_deadline,
                type: :submission_deadline,
                title: "Soumettre #{permit.permit_type.humanize}",
                permit: permit,
                urgency: permit.submission_urgency
              }
            end
          end
          
          # Expected decision dates
          if permit.under_review? && permit.expected_decision_date
            calendar_events << {
              date: permit.expected_decision_date,
              type: :expected_decision,
              title: "Décision attendue - #{permit.permit_type.humanize}",
              permit: permit,
              urgency: :medium
            }
          end
          
          # Expiry dates
          if permit.approved? && permit.expiry_date
            calendar_events << {
              date: permit.expiry_date,
              type: :expiry,
              title: "Expiration - #{permit.permit_type.humanize}",
              permit: permit,
              urgency: calculate_expiry_urgency(permit)
            }
          end
        end
        
        calendar_events.sort_by { |event| event[:date] }
      end

      private

      def check_submission_deadlines(permit)
        return [] unless permit.draft?
        
        urgency = permit.submission_urgency
        return [] if urgency == :not_applicable || urgency == :low
        
        [{
          permit: permit,
          type: :submission_due,
          urgency: urgency,
          message: generate_submission_message(permit),
          action_required: 'Finaliser et soumettre le dossier',
          deadline: calculate_submission_deadline(permit)
        }]
      end

      def check_response_deadlines(permit)
        return [] unless permit.under_review?
        
        overdue_days = permit.overdue_days
        return [] unless overdue_days && overdue_days > 0
        
        [{
          permit: permit,
          type: :response_overdue,
          urgency: overdue_days > 30 ? :high : :medium,
          message: "Réponse attendue depuis #{overdue_days} jours",
          action_required: 'Relancer les services instructeurs',
          overdue_days: overdue_days
        }]
      end

      def check_expiry_deadlines(permit)
        return [] unless permit.approved? && permit.expiry_date
        
        days_remaining = permit.days_until_expiry
        return [] unless days_remaining && days_remaining <= 90
        
        [{
          permit: permit,
          type: :expiring,
          urgency: calculate_expiry_urgency(permit),
          message: "Expire le #{permit.expiry_date.strftime('%d/%m/%Y')} (#{days_remaining} jours)",
          action_required: permit.expiry_action_required,
          days_remaining: days_remaining
        }]
      end

      def check_condition_deadlines(permit)
        alerts = []
        
        permit.permit_conditions.where(is_fulfilled: false).each do |condition|
          next unless condition.due_date
          
          days_remaining = (condition.due_date - Date.current).to_i
          
          if days_remaining < 0
            alerts << {
              permit: permit,
              condition: condition,
              type: :condition_overdue,
              urgency: :critical,
              message: "Condition en retard : #{condition.description}",
              action_required: 'Remplir la condition immédiatement',
              overdue_days: -days_remaining
            }
          elsif days_remaining <= 14
            alerts << {
              permit: permit,
              condition: condition,
              type: :condition_due_soon,
              urgency: :high,
              message: "Condition à remplir sous #{days_remaining} jours : #{condition.description}",
              action_required: 'Traiter la condition rapidement',
              days_remaining: days_remaining
            }
          end
        end
        
        alerts
      end

      def generate_submission_message(permit)
        case permit.submission_urgency
        when :critical
          "Soumission URGENTE requise - Risque de retard du projet"
        when :high
          "Soumission recommandée sous 30 jours"
        when :medium
          "Planifier la soumission dans les 2 mois"
        else
          "Préparer le dossier de #{permit.permit_type.humanize}"
        end
      end

      def calculate_submission_deadline(permit)
        construction_phase = project.phases.find_by(phase_type: 'construction')
        return nil unless construction_phase&.start_date
        
        processing_days = permit.estimated_processing_days
        buffer_days = 30
        
        construction_phase.start_date - (processing_days + buffer_days).days
      end

      def calculate_expiry_urgency(permit)
        days = permit.days_until_expiry
        
        case days
        when nil then :low
        when ..0 then :critical
        when 1..30 then :critical
        when 31..60 then :high
        when 61..90 then :medium
        else :low
        end
      end

      def urgency_score(urgency)
        case urgency
        when :critical then 4
        when :high then 3
        when :medium then 2
        when :low then 1
        else 0
        end
      end

      def build_deadline(item, date, type, description)
        {
          item: item,
          date: date,
          type: type,
          description: description,
          days_remaining: (date - Date.current).to_i,
          urgency: calculate_deadline_urgency(date)
        }
      end

      def calculate_deadline_urgency(date)
        days_remaining = (date - Date.current).to_i
        
        case days_remaining
        when ..0 then :critical
        when 1..7 then :high
        when 8..30 then :medium
        else :low
        end
      end
    end
  end
end