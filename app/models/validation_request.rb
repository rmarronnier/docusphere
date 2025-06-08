class ValidationRequest < ApplicationRecord
  belongs_to :document
  belongs_to :requester, class_name: 'User'
  has_many :document_validations, dependent: :destroy
  has_many :validators, through: :document_validations, source: :validator
  
  validates :min_validations, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected completed] }
  
  # Declare attribute type for enum
  attribute :status, :string
  
  enum status: {
    pending: 'pending',
    approved: 'approved',
    rejected: 'rejected', 
    completed: 'completed'
  }
  
  scope :for_requester, ->(user) { where(requester: user) }
  scope :active, -> { where(status: ['pending', 'approved']) }
  scope :for_validator, ->(user) { 
    joins(:document_validations).where(document_validations: { validator: user }) 
  }
  
  after_create :create_validator_tasks
  
  def add_validators(users)
    users.each do |user|
      document_validations.create!(
        document: document,
        validator: user,
        status: 'pending'
      )
    end
    notify_validators
  end
  
  def check_completion!
    Rails.logger.info "ValidationRequest#check_completion! called for request #{id}, current status: #{status}"
    return if approved? || rejected? || completed?
    
    # Check if any validation was rejected (rejection is definitive)
    if document_validations.rejected.exists?
      Rails.logger.info "Found rejected validation, updating status to rejected"
      update!(
        status: 'rejected',
        completed_at: Time.current
      )
      notify_rejection
      return
    end
    
    # Check if minimum validations reached
    approved_count = document_validations.approved.count
    Rails.logger.info "Approved count: #{approved_count}, min_validations: #{min_validations}"
    
    if approved_count >= min_validations
      Rails.logger.info "Minimum validations reached, updating status to approved"
      update!(
        status: 'approved',
        completed_at: Time.current
      )
      notify_approval
    end
  end
  
  def validation_progress
    {
      total_validators: document_validations.count,
      pending: document_validations.pending.count,
      approved: document_validations.approved.count,
      rejected: document_validations.rejected.count,
      min_required: min_validations,
      progress_percentage: progress_percentage
    }
  end
  
  def progress_percentage
    return 0 if document_validations.count == 0
    
    completed_validations = document_validations.completed.count
    (completed_validations.to_f / document_validations.count * 100).round(1)
  end
  
  def can_be_completed?
    return false if rejected?
    
    document_validations.approved.count >= min_validations
  end
  
  def has_rejection?
    document_validations.rejected.exists?
  end
  
  def pending_validators
    User.joins(:document_validations)
        .where(document_validations: { validation_request: self, status: 'pending' })
  end
  
  def rejecting_validators
    User.joins(:document_validations)
        .where(document_validations: { validation_request: self, status: 'rejected' })
  end
  
  def approving_validators
    User.joins(:document_validations)
        .where(document_validations: { validation_request: self, status: 'approved' })
  end
  
  private
  
  def create_validator_tasks
    # This will be called after validators are added via add_validators
  end
  
  def notify_validators
    NotificationService.notify_validation_requested(self)
  end
  
  def notify_approval
    # Send notification to requester about approval
    NotificationService.notify_validation_approved(self)
    Rails.logger.info "Validation request #{id} approved for document #{document.title}"
  end
  
  def notify_rejection
    # Send notification to requester about rejection  
    NotificationService.notify_validation_rejected(self)
    Rails.logger.info "Validation request #{id} rejected for document #{document.title}"
  end
end
