module Immo
  module Promo
    class Milestone < ApplicationRecord
      self.table_name = 'immo_promo_milestones'

      audited

      belongs_to :phase, class_name: 'Immo::Promo::Phase'
      
      # Documents polymorphic association
      has_many :documents, as: :documentable, dependent: :destroy
      
      # Access project through phase
      delegate :project, to: :phase
      
      # Business associations
      def related_permits
        return Document.none unless project
        project.permits.where(milestone_type: milestone_type)
      end
      
      def related_tasks
        return Immo::Promo::Task.none unless phase
        phase.tasks.where(task_type: task_type_for_milestone)
      end
      
      def blocking_dependencies
        return [] unless phase
        phase.phase_dependencies.where(dependent_phase: phase).includes(:prerequisite_phase)
      end

      validates :name, presence: true
      validates :milestone_type, presence: true
      validates :status, presence: true

      # Define enums before validations that reference them
      enum milestone_type: {
        permit_submission: 'permit_submission',
        permit_approval: 'permit_approval',
        construction_start: 'construction_start',
        construction_completion: 'construction_completion',
        delivery: 'delivery',
        legal_deadline: 'legal_deadline'
      }, _prefix: true

      enum status: {
        pending: 'pending',
        in_progress: 'in_progress',
        completed: 'completed',
        delayed: 'delayed'
      }, _prefix: true

      scope :critical, -> { where(is_critical: true) }
      scope :upcoming, -> { where('target_date > ?', Time.current) }
      scope :overdue, -> { where('target_date < ? AND status != ?', Time.current, 'completed') }
      scope :recent, -> { order(target_date: :desc) }

      def is_overdue?
        target_date && Time.current > target_date && !status_completed?
      end
      
      def completed?
        status_completed?
      end

      def days_until_deadline
        return nil unless target_date
        (target_date.to_date - Date.current).to_i
      end
      
      # Alias for test compatibility
      alias_method :days_until_due, :days_until_deadline

      def completion_date
        completed_at || actual_date
      end

      def variance_in_days
        return nil unless target_date && completion_date
        (completion_date.to_date - target_date.to_date).to_i
      end

      def is_on_schedule?
        return true if completed? && variance_in_days && variance_in_days <= 0
        return true if status_pending? && days_until_deadline && days_until_deadline >= 0
        false
      end
      
      def pending?
        status_pending?
      end
      
      private
      
      def task_type_for_milestone
        case milestone_type
        when 'permit_submission' then 'administrative'
        when 'permit_approval' then 'administrative'  
        when 'construction_start' then 'technical'
        when 'construction_completion' then 'technical'
        when 'delivery' then 'commercial'
        when 'legal_deadline' then 'administrative'
        else 'technical'
        end
      end
    end
  end
end
