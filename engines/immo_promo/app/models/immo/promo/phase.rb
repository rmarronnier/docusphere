class Immo::Promo::Phase < ApplicationRecord
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
  has_many :prerequisite_dependencies, class_name: 'Immo::Promo::PhaseDependency', foreign_key: 'prerequisite_phase_id', dependent: :destroy
  has_many :prerequisite_phases, through: :prerequisite_dependencies, source: :dependent_phase

  validates :name, presence: true
  validates :phase_type, inclusion: { in: %w[studies permits construction reception delivery] }
  validates :status, inclusion: { in: %w[pending in_progress completed delayed cancelled] }
  validates :position, presence: true, uniqueness: { scope: :project_id }

  monetize :budget_cents, allow_nil: true
  monetize :actual_cost_cents, allow_nil: true

  enum phase_type: {
    studies: 'studies',
    permits: 'permits', 
    construction: 'construction',
    reception: 'reception',
    delivery: 'delivery'
  }

  enum status: {
    pending: 'pending',
    in_progress: 'in_progress',
    completed: 'completed',
    delayed: 'delayed',
    cancelled: 'cancelled'
  }

  scope :by_type, ->(type) { where(phase_type: type) }
  scope :active, -> { where.not(status: ['completed', 'cancelled']) }
  scope :critical, -> { where(is_critical: true) }
  scope :ordered, -> { order(:position) }

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

  private

  def schedule_required?
    true
  end
end