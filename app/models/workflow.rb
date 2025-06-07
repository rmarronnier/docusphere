class Workflow < ApplicationRecord
  include AASM
  
  belongs_to :organization
  belongs_to :user
  belongs_to :workflow_template, optional: true
  
  has_many :workflow_steps, dependent: :destroy
  has_many :workflow_submissions, dependent: :destroy
  has_many :documents, through: :workflow_submissions, source: :submittable, source_type: 'Document'
  
  validates :name, presence: true
  validates :description, presence: true
  
  aasm column: 'status' do
    state :draft, initial: true
    state :active
    state :paused
    state :completed
    state :cancelled
    
    event :activate do
      transitions from: :draft, to: :active
    end
    
    event :pause do
      transitions from: :active, to: :paused
    end
    
    event :resume do
      transitions from: :paused, to: :active
    end
    
    event :complete do
      transitions from: :active, to: :completed
    end
    
    event :cancel do
      transitions from: [:draft, :active, :paused], to: :cancelled
    end
  end
  
  def can_be_activated?
    draft? && workflow_steps.any?
  end
  
  def progress_percentage
    return 0 if workflow_steps.empty?
    
    completed_count = workflow_steps.where(status: 'completed').count
    total_count = workflow_steps.count
    
    ((completed_count.to_f / total_count) * 100).round(2)
  end
end