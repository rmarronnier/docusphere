module Immo
  module Promo
    class Phase < ApplicationRecord
      self.table_name = 'immo_promo_phases'

      include Schedulable
      include WorkflowManageable
      audited

      belongs_to :project, class_name: 'Immo::Promo::Project'
      belongs_to :responsible_user, class_name: 'User', optional: true
      has_many :tasks, class_name: 'Immo::Promo::Task', dependent: :destroy
      has_many :milestones, class_name: 'Immo::Promo::Milestone', dependent: :destroy
      has_many :phase_dependencies, class_name: 'Immo::Promo::PhaseDependency', foreign_key: 'dependent_phase_id', dependent: :destroy
      has_many :dependent_phases, through: :phase_dependencies, source: :prerequisite_phase
      has_many :inverse_phase_dependencies, class_name: 'Immo::Promo::PhaseDependency', foreign_key: 'prerequisite_phase_id', dependent: :destroy
      has_many :prerequisite_phases, through: :inverse_phase_dependencies, source: :dependent_phase

      validates :name, presence: true
      validates :phase_type, inclusion: { in: %w[studies permits construction finishing delivery reception other] }
      validates :status, inclusion: { in: %w[pending in_progress completed on_hold cancelled] }
      validates :position, presence: true, uniqueness: { scope: :project_id }, numericality: { greater_than: 0 }

      monetize :budget_cents, allow_nil: true
      monetize :actual_cost_cents, allow_nil: true

      enum phase_type: {
        studies: 'studies',
        permits: 'permits',
        construction: 'construction',
        finishing: 'finishing',
        delivery: 'delivery',
        reception: 'reception',
        other: 'other'
      }

      enum status: {
        pending: 'pending',
        in_progress: 'in_progress',
        completed: 'completed',
        on_hold: 'on_hold',
        cancelled: 'cancelled'
      }

      scope :by_type, ->(type) { where(phase_type: type) }
      scope :active, -> { where.not(status: [ 'completed', 'cancelled' ]) }
      scope :critical, -> { where(is_critical: true) }
      scope :ordered, -> { order(:position) }
      scope :delayed, -> { where('end_date < ? AND status NOT IN (?)', Date.current, ['completed', 'cancelled']) }

      def can_start?
        dependent_phases.all? { |phase| phase.completed? }
      end

      def completion_percentage
        return 0 if tasks.empty?
        completed_tasks = tasks.where(status: 'completed').count
        (completed_tasks.to_f / tasks.count * 100).round(2)
      end

      def is_delayed?
        return false unless end_date
        Time.current > end_date && !completed?
      end

      def dependent_phases_count
        dependent_phases.count
      end

      def critical_path?
        is_critical
      end
      
      def task_completion_percentage
        completion_percentage
      end
      
      def days_remaining
        return 0 unless end_date
        days = (end_date.to_date - Date.current).to_i
        days > 0 ? days : 0
      end
      
      # Scopes supplémentaires
      scope :delayed, -> { where.not(status: ['completed', 'cancelled']).where('end_date < ?', Date.current) }

      private

      def schedule_required?
        true
      end
    end
  end
end
