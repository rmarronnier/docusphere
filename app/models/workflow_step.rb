class WorkflowStep < ApplicationRecord
  include AASM
  
  belongs_to :workflow
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :assigned_to_group, class_name: 'UserGroup', optional: true
  belongs_to :completed_by, class_name: 'User', optional: true
  
  has_many :workflow_submissions, dependent: :destroy
  
  validates :name, presence: true
  validates :position, presence: true
  validates :step_type, presence: true, inclusion: { in: %w[manual automatic conditional parallel] }
  validates :position, uniqueness: { scope: :workflow_id }
  
  scope :ordered, -> { order(:position) }
  scope :manual, -> { where(step_type: 'manual') }
  
  aasm column: 'status' do
    state :pending, initial: true
    state :in_progress
    state :completed
    state :rejected
    state :skipped
    
    event :start do
      transitions from: :pending, to: :in_progress
    end
    
    event :complete do
      transitions from: :in_progress, to: :completed
      after do
        self.completed_at = Time.current
        save!
      end
    end
    
    event :reject do
      transitions from: :in_progress, to: :rejected
    end
    
    event :skip do
      transitions from: [:pending, :in_progress], to: :skipped
    end
  end
  
  def next_step
    workflow.workflow_steps.ordered.where('position > ?', position).first
  end
  
  def previous_step
    workflow.workflow_steps.ordered.where('position < ?', position).last
  end
  
  def can_be_completed_by?(user)
    return true if assigned_to.nil? # Unassigned steps can be completed by anyone
    assigned_to == user
  end
  
  def estimated_duration_in_hours
    duration = settings&.dig('estimated_duration') || 0
    return 0 if duration == 0
    duration / 3600.0
  end
  
  def estimated_duration
    settings&.dig('estimated_duration') || 0
  end
  
  def estimated_duration=(value)
    self.settings ||= {}
    self.settings['estimated_duration'] = value
  end
end