module Immo
  module Promo
    class Task < ApplicationRecord
      self.table_name = 'immo_promo_tasks'

      include Schedulable
      include WorkflowManageable
      include Immo::Promo::Documentable
      audited

      belongs_to :phase, class_name: 'Immo::Promo::Phase'
      belongs_to :assigned_to, class_name: 'User', optional: true
      belongs_to :stakeholder, class_name: 'Immo::Promo::Stakeholder', optional: true
      has_many :task_dependencies, class_name: 'Immo::Promo::TaskDependency', foreign_key: 'dependent_task_id', dependent: :destroy
      has_many :prerequisite_tasks, through: :task_dependencies, source: :prerequisite_task
      has_many :inverse_task_dependencies, class_name: 'Immo::Promo::TaskDependency', foreign_key: 'prerequisite_task_id', dependent: :destroy
      has_many :dependent_tasks, through: :inverse_task_dependencies, source: :dependent_task
      has_many :time_logs, class_name: 'Immo::Promo::TimeLog', dependent: :destroy

      has_many_attached :deliverables
      has_many_attached :references

      validates :name, presence: true
      validates :task_type, inclusion: { in: %w[planning execution review approval milestone administrative technical other] }
      validates :status, inclusion: { in: %w[pending in_progress completed blocked cancelled] }
      validates :priority, inclusion: { in: %w[low medium high critical] }
      validates :estimated_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

      monetize :estimated_cost_cents, allow_nil: true
      monetize :actual_cost_cents, allow_nil: true
      
      # Store required skills in checklist JSONB column
      store_accessor :checklist, :required_skills

      enum task_type: {
        planning: 'planning',
        execution: 'execution',
        review: 'review',
        approval: 'approval',
        milestone: 'milestone',
        administrative: 'administrative',
        technical: 'technical',
        other: 'other'
      }

      enum status: {
        pending: 'pending',
        in_progress: 'in_progress',
        completed: 'completed',
        blocked: 'blocked',
        cancelled: 'cancelled'
      }

      enum priority: {
        low: 'low',
        medium: 'medium',
        high: 'high',
        critical: 'critical'
      }

      scope :by_type, ->(type) { where(task_type: type) }
      scope :by_priority, ->(priority) { where(priority: priority) }
      scope :assigned_to_user, ->(user) { where(assigned_to: user) }
      scope :overdue, -> { where('immo_promo_tasks.end_date < ? AND immo_promo_tasks.status != ?', Time.current, 'completed') }
      scope :due_soon, -> { where(end_date: Time.current..7.days.from_now) }

      def can_start?
        prerequisite_tasks.all? { |task| task.completed? }
      end

      def completion_percentage
        return 0 unless estimated_hours && estimated_hours > 0
        logged_hours = time_logs.sum(:hours)
        [ (logged_hours / estimated_hours * 100).round(2), 100 ].min
      end

      def actual_hours
        total_logged_hours
      end

      def is_overdue?
        end_date && Time.current > end_date && !completed?
      end

      def days_remaining
        return 0 unless end_date
        [ (end_date.to_date - Date.current).to_i, 0 ].max
      end

      def total_logged_hours
        time_logs.sum(:hours)
      end

      def project
        phase.project
      end
      
      def progress_percentage
        completion_percentage
      end
      
      def logged_hours
        total_logged_hours
      end
      
      def completion_status
        case status
        when 'completed'
          'Terminée'
        when 'pending'
          'En attente'
        else
          if is_overdue?
            'En retard'
          else
            "#{progress_percentage}%"
          end
        end
      end
      
      # Scopes supplémentaires
      scope :high_priority, -> { where(priority: ['high', 'critical']) }

      private

      def schedule_required?
        true
      end

      def required_document_types
        case task_type
        when 'planning'
          %w[project plan]
        when 'execution'
          %w[technical]
        when 'review', 'approval'
          %w[administrative]
        when 'milestone'
          %w[administrative]
        when 'administrative'
          %w[administrative]
        when 'technical'
          %w[technical plan]
        else
          %w[project]
        end
      end
    end
  end
end
