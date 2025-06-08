class Immo::Promo::Milestone < ApplicationRecord
  self.table_name = 'immo_promo_milestones'
  
  audited

  belongs_to :phase, class_name: 'Immo::Promo::Phase'
  has_one :project, through: :phase, class_name: 'Immo::Promo::Project'

  validates :name, presence: true
  validates :milestone_type, inclusion: { 
    in: %w[permit_submission permit_approval construction_start construction_completion delivery legal_deadline] 
  }
  validates :status, inclusion: { in: %w[pending in_progress completed delayed] }

  # Declare attribute type for enum
  attribute :milestone_type, :string
  
  enum milestone_type: {
    permit_submission: 'permit_submission',
    permit_approval: 'permit_approval',
    construction_start: 'construction_start',
    construction_completion: 'construction_completion', 
    delivery: 'delivery',
    legal_deadline: 'legal_deadline'
  }

  enum status: {
    pending: 'pending',
    in_progress: 'in_progress',
    completed: 'completed',
    delayed: 'delayed'
  }

  scope :critical, -> { where(is_critical: true) }
  scope :upcoming, -> { where('target_date > ?', Time.current) }
  scope :overdue, -> { where('target_date < ? AND status != ?', Time.current, 'completed') }
  scope :recent, -> { order(target_date: :desc) }

  def is_overdue?
    target_date && Time.current > target_date && !completed?
  end

  def days_until_deadline
    return nil unless target_date
    (target_date.to_date - Date.current).to_i
  end

  def completion_date
    completed_at || actual_date
  end

  def variance_in_days
    return nil unless target_date && completion_date
    (completion_date.to_date - target_date.to_date).to_i
  end

  def is_on_schedule?
    return true if completed? && variance_in_days && variance_in_days <= 0
    return true if pending? && days_until_deadline && days_until_deadline >= 0
    false
  end

  private

  def schedule_required?
    true
  end
end