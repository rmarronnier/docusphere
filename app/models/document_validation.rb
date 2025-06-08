class DocumentValidation < ApplicationRecord
  belongs_to :document
  belongs_to :validator, class_name: 'User'
  belongs_to :validation_request
  
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validates :comment, presence: true, if: :rejected?
  validates :validator_id, uniqueness: { scope: [:document_id, :validation_request_id] }
  
  # Declare attribute type for enum
  attribute :status, :string
  
  enum status: {
    pending: 'pending',
    approved: 'approved', 
    rejected: 'rejected'
  }
  
  scope :for_validator, ->(user) { where(validator: user) }
  scope :completed, -> { where.not(status: 'pending') }
  scope :pending_validation, -> { where(status: 'pending') }
  
  before_update :set_validated_at, if: :status_changed?
  after_update :check_validation_completion, if: :status_changed?
  
  def approve!(comment: nil)
    update!(
      status: 'approved',
      comment: comment,
      validated_at: Time.current
    )
  end
  
  def reject!(comment:)
    update!(
      status: 'rejected', 
      comment: comment,
      validated_at: Time.current
    )
  end
  
  def completed?
    !pending?
  end
  
  def validator_name
    validator&.full_name || 'Utilisateur supprimé'
  end
  
  private
  
  def set_validated_at
    self.validated_at = Time.current if status_changed? && !pending?
  end
  
  def check_validation_completion
    Rails.logger.info "DocumentValidation#check_validation_completion called for validation #{id}, status: #{status}"
    validation_request&.reload&.check_completion!
  end
end
