module Immo
  module Promo
    class Permit < ApplicationRecord
      self.table_name = 'immo_promo_permits'

      include Schedulable
      include WorkflowManageable
      audited

      # Alias pour Schedulable concern
      alias_attribute :start_date, :submitted_date
      alias_attribute :end_date, :expiry_date

      belongs_to :project, class_name: 'Immo::Promo::Project'
      belongs_to :submitted_by, class_name: 'User', optional: true
      belongs_to :approved_by, class_name: 'User', optional: true
      has_many :permit_conditions, class_name: 'Immo::Promo::PermitCondition', dependent: :destroy
      has_many_attached :permit_documents
      has_many_attached :response_documents
      
      # Compatibilité avec les tests
      has_many_attached :documents

      validates :permit_type, presence: true, inclusion: {
        in: %w[urban_planning construction demolition environmental modification declaration]
      }
      validates :status, inclusion: {
        in: %w[draft submitted under_review additional_info_requested approved denied appeal]
      }
      validates :permit_number, presence: true, uniqueness: { scope: :project_id }
      validates :issuing_authority, presence: true

      # Aliases for compatibility
      alias_attribute :reference_number, :permit_number
      alias_attribute :authority, :issuing_authority
      alias_attribute :start_date, :submitted_date
      alias_attribute :end_date, :expiry_date

      enum permit_type: {
        urban_planning: 'urban_planning',
        construction: 'construction',
        demolition: 'demolition',
        environmental: 'environmental',
        modification: 'modification',
        declaration: 'declaration'
      }

      enum status: {
        draft: 'draft',
        submitted: 'submitted',
        under_review: 'under_review',
        additional_info_requested: 'additional_info_requested',
        approved: 'approved',
        denied: 'denied',
        appeal: 'appeal'
      }

      scope :by_type, ->(type) { where(permit_type: type) }
      scope :by_status, ->(status) { where(status: status) }
      scope :critical, -> { where(permit_type: [ 'construction', 'urban_planning' ]) }
      scope :expiring_soon, ->(days = 90) { approved.where('expiry_date <= ?', days.days.from_now) }
      scope :pending, -> { where.not(status: ['approved', 'denied']) }
      scope :approved, -> { where(status: 'approved') }
      scope :overdue_response, -> { under_review.where('expected_decision_date < ?', Date.current) }
      scope :needs_submission, -> { draft.joins(:project).where('projects.start_date <= ?', 3.months.from_now) }

      def days_until_expiry
        return nil unless expiry_date
        (expiry_date.to_date - Date.current).to_i
      end

      def is_expired?
        expiry_date && Date.current > expiry_date
      end

      def is_expiring_soon?
        return false unless expiry_date
        days_until_expiry <= 90 && days_until_expiry > 0
      end

      def review_period_remaining
        return nil unless submission_date && expected_decision_date
        (expected_decision_date.to_date - Date.current).to_i
      end

      def can_start_construction?
        approved? && permit_type == 'construction'
      end

      def has_conditions?
        permit_conditions.exists?
      end

      def outstanding_conditions
        permit_conditions.where(is_fulfilled: false)
      end

      def all_conditions_fulfilled?
        permit_conditions.all?(&:is_fulfilled)
      end

      def permit_name
        "#{permit_type.humanize} - #{reference_number}"
      end

      # Méthodes pour la compatibilité avec les tests
      def is_approved?
        approved?
      end

      def is_pending?
        %w[submitted under_review additional_info_requested].include?(status)
      end

      def processing_time_days
        return 0 unless submitted_date.present?
        
        if approved_date.present?
          (approved_date.to_date - submitted_date.to_date).to_i
        else
          (Date.current - submitted_date.to_date).to_i
        end
      end

      def all_conditions_met?
        return true if permit_conditions.empty?
        permit_conditions.where(status: 'met').count == permit_conditions.count
      end

      # Méthodes pour compatibilité
      def reference
        permit_number
      end
      
      def title
        permit_name
      end
      
      def authority
        issuing_authority
      end
      
      # Nouvelles méthodes métier pour la refactorisation
      def submission_urgency
        return :not_applicable unless draft?
        return :critical if should_submit_immediately?
        return :high if should_submit_soon?
        return :medium if should_submit_within_month?
        :low
      end
      
      def expiry_action_required
        return nil unless approved? && expiry_date
        
        case days_until_expiry
        when nil then nil
        when ..0 then 'Permis expiré - Renouveler immédiatement'
        when 1..30 then 'Commencer les travaux immédiatement ou demander une prorogation'
        when 31..60 then 'Planifier le démarrage des travaux ou préparer une demande de prorogation'
        when 61..90 then 'Surveiller et planifier le démarrage des travaux'
        else 'Aucune action immédiate requise'
        end
      end
      
      def overdue_days
        return nil unless under_review? && expected_decision_date
        return 0 if expected_decision_date >= Date.current
        (Date.current - expected_decision_date).to_i
      end
      
      def estimated_processing_days
        case permit_type
        when 'construction'
          project.total_surface_area > 1000 ? 90 : 60
        when 'urban_planning'
          90
        when 'demolition'
          45
        when 'environmental'
          120
        when 'modification'
          30
        when 'declaration'
          30
        else
          60
        end
      end
      
      def expected_decision_date
        return nil unless submitted_date
        submitted_date + estimated_processing_days.days
      end
      
      def urgency_level
        if draft? && submission_urgency == :critical
          :critical
        elsif under_review? && overdue_days && overdue_days > 30
          :high
        elsif approved? && days_until_expiry && days_until_expiry < 30
          :critical
        elsif approved? && days_until_expiry && days_until_expiry < 60
          :high
        else
          :medium
        end
      end

      private

      def schedule_required?
        # Les dates ne sont requises que pour les permis soumis ou en cours
        submitted? || under_review? || approved?
      end
      
      def should_submit_immediately?
        project.phases.where(phase_type: 'construction').any? { |p| p.start_date && p.start_date <= 4.months.from_now }
      end
      
      def should_submit_soon?
        project.phases.where(phase_type: 'construction').any? { |p| p.start_date && p.start_date <= 6.months.from_now }
      end
      
      def should_submit_within_month?
        project.phases.where(phase_type: 'construction').any? { |p| p.start_date && p.start_date <= 8.months.from_now }
      end
    end
  end
end
