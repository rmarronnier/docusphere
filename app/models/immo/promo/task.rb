class Immo::Promo::Task < ApplicationRecord
  self.table_name = 'immo_promo_tasks'
  
  include Schedulable
  include WorkflowManageable
  audited

  belongs_to :phase, class_name: 'Immo::Promo::Phase'
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :stakeholder, class_name: 'Immo::Promo::Stakeholder', optional: true
  has_many :task_dependencies, class_name: 'Immo::Promo::TaskDependency', foreign_key: 'dependent_task_id', dependent: :destroy
  has_many :dependent_tasks, through: :task_dependencies, source: :prerequisite_task
  has_many :prerequisite_dependencies, class_name: 'Immo::Promo::TaskDependency', foreign_key: 'prerequisite_task_id', dependent: :destroy
  has_many :prerequisite_tasks, through: :prerequisite_dependencies, source: :dependent_task
  has_many :time_logs, class_name: 'Immo::Promo::TimeLog', dependent: :destroy

  has_many_attached :deliverables
  has_many_attached :references

  validates :name, presence: true
  validates :task_type, inclusion: { in: %w[administrative technical legal financial quality_control] }
  validates :status, inclusion: { in: %w[pending in_progress completed on_hold cancelled] }
  validates :priority, inclusion: { in: %w[low medium high critical] }

  monetize :estimated_cost_cents, allow_nil: true
  monetize :actual_cost_cents, allow_nil: true

  enum task_type: {
    administrative: 'administrative',
    technical: 'technical',
    legal: 'legal',
    financial: 'financial',
    quality_control: 'quality_control'
  }

  enum status: {
    pending: 'pending',
    in_progress: 'in_progress', 
    completed: 'completed',
    on_hold: 'on_hold',
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
    [(logged_hours / estimated_hours * 100).round(2), 100].min
  end

  def actual_hours
    total_logged_hours
  end

  def is_overdue?
    end_date && Time.current > end_date && !completed?
  end

  def days_remaining
    return 0 unless end_date
    [(end_date.to_date - Date.current).to_i, 0].max
  end

  def total_logged_hours
    time_logs.sum(:hours)
  end

  def project
    phase.project
  end

  private

  def schedule_required?
    true
  end
end