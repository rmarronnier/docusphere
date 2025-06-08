class WorkflowStep < ApplicationRecord
  include AASM
  
  belongs_to :workflow
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :assigned_to_group, class_name: 'UserGroup', optional: true
  belongs_to :completed_by, class_name: 'User', optional: true
  
  validates :name, presence: true
  validates :position, presence: true
  
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
end