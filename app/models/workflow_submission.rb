class WorkflowSubmission < ApplicationRecord
  include AASM
  
  belongs_to :workflow
  belongs_to :submittable, polymorphic: true
  belongs_to :submitted_by, class_name: 'User'
  belongs_to :current_step, class_name: 'WorkflowStep', optional: true
  belongs_to :decided_by, class_name: 'User', optional: true
  
  validates :workflow_id, uniqueness: { scope: [:submittable_type, :submittable_id] }
  validates :status, presence: true
  validates :priority, inclusion: { in: %w[low normal high urgent] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :overdue, -> { where('due_date < ? AND status NOT IN (?)', Time.current, ['completed', 'cancelled']) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 WHEN 'low' THEN 3 END")) }
  
  before_create :set_submitted_at
  
  aasm column: 'status' do
    state :pending, initial: true
    state :in_progress
    state :waiting_for_approval
    state :approved
    state :rejected
    state :returned_for_revision
    state :completed
    state :cancelled
    
    event :start do
      transitions from: :pending, to: :in_progress
      after do
        self.started_at = Time.current
      end
    end
    
    event :submit_for_approval do
      transitions from: [:in_progress, :returned_for_revision], to: :waiting_for_approval
    end
    
    event :approve do
      transitions from: :waiting_for_approval, to: :approved
      after do
        self.decision = 'approved'
        self.decided_at = Time.current
      end
    end
    
    event :reject do
      transitions from: :waiting_for_approval, to: :rejected
      after do
        self.decision = 'rejected'
        self.decided_at = Time.current
      end
    end
    
    event :return_for_revision do
      transitions from: :waiting_for_approval, to: :returned_for_revision
      after do
        self.decision = 'returned_for_revision'
        self.decided_at = Time.current
      end
    end
    
    event :complete do
      transitions from: [:approved, :in_progress], to: :completed
      after do
        self.completed_at = Time.current
      end
    end
    
    event :cancel do
      transitions from: [:pending, :in_progress, :waiting_for_approval], to: :cancelled
    end
  end
  
  def overdue?
    due_date.present? && due_date < Time.current && !completed? && !cancelled?
  end
  
  def days_until_due
    return nil unless due_date.present?
    (due_date.to_date - Date.current).to_i
  end
  
  private
  
  def set_submitted_at
    self.submitted_at ||= Time.current
  end
end