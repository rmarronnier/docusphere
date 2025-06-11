module Immo
  module Promo
    class Project < ::ApplicationRecord
      self.table_name = 'immo_promo_projects'

      include Addressable
      include Schedulable
      # include WorkflowManageable # Temporarily disabled - model mismatch
      include Authorizable
      include Immo::Promo::Documentable
      audited
      
      # Configure ownership
      owned_by :project_manager

      belongs_to :organization
      belongs_to :project_manager, class_name: 'User', optional: true
      has_many :phases, class_name: 'Immo::Promo::Phase', dependent: :destroy
      has_many :tasks, through: :phases, class_name: 'Immo::Promo::Task'
      has_many :lots, class_name: 'Immo::Promo::Lot', dependent: :destroy
      has_many :stakeholders, class_name: 'Immo::Promo::Stakeholder', dependent: :destroy
      has_many :permits, class_name: 'Immo::Promo::Permit', dependent: :destroy
      has_many :budgets, class_name: 'Immo::Promo::Budget', dependent: :destroy
      has_many :contracts, class_name: 'Immo::Promo::Contract', dependent: :destroy
      has_many :risks, class_name: 'Immo::Promo::Risk', dependent: :destroy
      has_many :milestones, through: :phases, class_name: 'Immo::Promo::Milestone'
      has_many :progress_reports, class_name: 'Immo::Promo::ProgressReport', dependent: :destroy
      has_many :reservations, through: :lots, class_name: 'Immo::Promo::Reservation'

      has_many_attached :technical_documents
      has_many_attached :administrative_documents
      has_many_attached :financial_documents

      validates :name, presence: true
      validates :project_type, presence: true
      validates :status, presence: true

      before_validation :set_defaults

      private

      def set_defaults
        self.slug ||= name.parameterize if name.present?
        self.reference_number ||= "PROJ-#{organization.id}-#{Time.current.strftime('%Y%m%d%H%M%S')}" if organization.present?
      end

      public

      monetize :total_budget_cents, allow_nil: true
      monetize :current_budget_cents, allow_nil: true

      # Alias for Schedulable concern compatibility
      alias_attribute :end_date, :expected_completion_date
      
      # Alias for test compatibility
      alias_attribute :reference, :reference_number

      enum project_type: {
        residential: 'residential',
        commercial: 'commercial',
        mixed: 'mixed',
        office: 'office',
        retail: 'retail',
        industrial: 'industrial'
      }

      enum status: {
        planning: 'planning',
        pre_construction: 'pre_construction',
        construction: 'construction',
        finishing: 'finishing',
        delivered: 'delivered',
        completed: 'completed',
        cancelled: 'cancelled'
      }

      scope :active, -> { where.not(status: [ 'completed', 'cancelled' ]) }
      scope :by_type, ->(type) { where(project_type: type) }
      scope :by_manager, ->(manager) { where(project_manager: manager) }

      def completion_percentage
        return 0 if phases.empty?
        completed_phases = phases.where(status: 'completed').count
        (completed_phases.to_f / phases.count * 100).round(2)
      end

      def is_delayed?
        return false unless end_date
        phases.where('end_date > ? AND status != ?', end_date, 'completed').exists?
      end

      def total_surface_area
        lots.sum(:surface_area)
      rescue ActiveRecord::StatementInvalid
        0
      end

      def can_start_construction?
        permits.where(permit_type: 'construction', status: 'approved').exists?
      rescue ActiveRecord::StatementInvalid
        false
      end
      
      def active?
        !completed? && !cancelled?
      end

      # Progress Calculation Methods
      def calculate_overall_progress
        return 0 if phases.empty?
        
        # Task-based calculation for more accurate progress
        all_tasks = phases.joins(:tasks).count
        return 0 if all_tasks.zero?
        
        completed_tasks = phases.joins(:tasks).where(immo_promo_tasks: { status: 'completed' }).count
        ((completed_tasks.to_f / all_tasks) * 100).round(2)
      end
      
      def calculate_phase_based_progress
        return 0 if phases.empty?
        
        # Weighted progress based on phase importance
        total_weight = 0
        weighted_progress = 0
        
        phases.each do |phase|
          weight = phase_weight(phase)
          total_weight += weight
          weighted_progress += weight * phase.completion_percentage
        end
        
        return 0 if total_weight.zero?
        (weighted_progress / total_weight).round(2)
      end
      
      # Critical Path Methods
      def critical_phases
        # Get critical phases or phases with critical types
        critical_or_important = phases.where(is_critical: true)
                                     .or(phases.where(phase_type: ['permits', 'construction']))
        
        # Get phases with dependencies (separate query to avoid join issues with .or)
        with_dependencies = phases.joins(:phase_dependencies).distinct
        
        # Combine results
        Immo::Promo::Phase.where(
          id: critical_or_important.pluck(:id) + with_dependencies.pluck(:id)
        ).distinct.order(:position)
      end
      
      def has_critical_path_delays?
        critical_phases.any?(&:is_delayed?)
      end
      
      # Budget Methods
      def budget_usage_percentage
        return 0 unless total_budget && current_budget && total_budget.amount > 0
        ((current_budget.amount.to_f / total_budget.amount) * 100).round(2)
      end
      
      def is_over_budget?
        total_budget && current_budget && current_budget > total_budget
      end
      
      def remaining_budget
        return nil unless total_budget && current_budget
        total_budget - current_budget
      end
      
      # Milestone Methods
      def critical_milestones
        milestones.where(is_critical: true)
      end
      
      def overdue_milestones
        milestones.where('immo_promo_milestones.target_date < ? AND immo_promo_milestones.status != ?', Date.current, 'completed')
      end
      
      def upcoming_milestones(days_ahead = 7)
        milestones.where(
          target_date: Date.current..days_ahead.days.from_now,
          status: 'pending'
        )
      end
      
      # Risk Methods
      def active_risks
        risks.active
      end
      
      def high_priority_risks
        risks.active.where(severity: 'high').or(risks.active.where(probability: 'high'))
      end
      
      # Stakeholder Methods
      def available_stakeholders
        stakeholders.active.joins(:tasks)
                   .where(immo_promo_tasks: { status: ['pending', 'in_progress'] })
                   .group('immo_promo_stakeholders.id')
                   .having('COUNT(immo_promo_tasks.id) < 5')
      end
      
      def overloaded_stakeholders
        stakeholders.active.joins(:tasks)
                   .where(immo_promo_tasks: { status: ['pending', 'in_progress'] })
                   .group('immo_promo_stakeholders.id')
                   .having('SUM(immo_promo_tasks.estimated_hours) > 40')
      end
      
      # Permit Methods
      def expiring_permits(days_ahead = 30)
        permits.where(
          expiry_date: Date.current..days_ahead.days.from_now,
          status: 'approved'
        )
      end
      
      def missing_critical_permits
        required_permits = case status
        when 'construction'
          ['construction', 'environmental']
        when 'pre_construction'
          ['planning', 'demolition']
        else
          []
        end
        
        required_permits - permits.where(status: 'approved').pluck(:permit_type)
      end
      
      # Validation Methods
      def validate_phase_dependencies
        errors = []
        phases.each do |phase|
          unless phase.can_start?
            prerequisite_names = phase.prerequisite_phases.where.not(status: 'completed').pluck(:name)
            if prerequisite_names.any?
              errors << "Phase '#{phase.name}' cannot start: prerequisites not completed (#{prerequisite_names.join(', ')})"
            end
          end
        end
        errors
      end
      
      def validate_construction_readiness
        return [] unless status == 'construction'
        
        errors = []
        errors << "Cannot start construction without approved construction permit" unless can_start_construction?
        errors << "Missing environmental permit" unless permits.where(permit_type: 'environmental', status: 'approved').exists?
        errors
      end

      # Callbacks
      before_validation :set_slug, on: :create
      before_validation :generate_reference_number, on: :create
      
      private

      def address_required?
        true
      end
      
      def set_slug
        self.slug = name.parameterize if name.present? && slug.blank?
      end
      
      def generate_reference_number
        if reference_number.blank? && organization.present?
          timestamp = Time.current.strftime('%Y%m%d%H%M%S')
          self.reference_number = "PROJ-#{organization.id}-#{timestamp}"
        end
      end

      def schedule_required?
        true
      end
      
      def phase_weight(phase)
        case phase.phase_type
        when 'construction' then 50
        when 'permits' then 30
        when 'studies' then 15
        when 'reception' then 3
        when 'delivery' then 2
        else 10
        end
      end

      def required_document_types
        case project_type
        when 'residential', 'mixed'
          %w[project technical administrative financial legal permit plan]
        when 'commercial', 'office', 'retail'
          %w[project technical administrative financial legal permit plan]
        when 'industrial'
          %w[project technical administrative financial legal permit plan environmental]
        else
          %w[project technical administrative financial]
        end
      end
    end
  end
end
