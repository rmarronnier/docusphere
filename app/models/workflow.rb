class Workflow < ApplicationRecord
  include AASM
  
  belongs_to :space
  belongs_to :user
  belongs_to :workflow_template, optional: true
  
  has_many :workflow_steps, dependent: :destroy
  has_many :workflow_documents, dependent: :destroy
  has_many :documents, through: :workflow_documents
  
  validates :name, presence: true
  
  aasm column: 'status' do
    state :draft, initial: true
    state :active
    state :completed
    state :cancelled
    
    event :activate do
      transitions from: :draft, to: :active
    end
    
    event :complete do
      transitions from: :active, to: :completed
    end
    
    event :cancel do
      transitions from: [:draft, :active], to: :cancelled
    end
  end
end