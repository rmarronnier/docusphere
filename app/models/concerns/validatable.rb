# Concern for adding validation workflow capabilities to models
module Validatable
  extend ActiveSupport::Concern

  included do
    has_many :validation_requests, as: :validatable, dependent: :destroy
    has_many :document_validations, as: :validatable, dependent: :destroy
    has_many :validators, through: :document_validations, source: :validator
    
    scope :pending_validation, -> { joins(:validation_requests).where(validation_requests: { status: 'pending' }) }
    scope :validated, -> { joins(:validation_requests).where(validation_requests: { status: 'approved' }) }
    scope :rejected, -> { joins(:validation_requests).where(validation_requests: { status: 'rejected' }) }
  end

  # Request validation from specific validators
  def request_validation(requester:, validators:, min_validations: 1, due_date: nil, notes: nil)
    return false if validation_pending?
    
    validation_request = validation_requests.create!(
      requester: requester,
      min_validations: min_validations,
      due_date: due_date,
      notes: notes,
      status: 'pending'
    )
    
    validators.each do |validator|
      document_validations.create!(
        validation_request: validation_request,
        validator: validator,
        status: 'pending'
      )
    end
    
    validation_request
  end

  # Current active validation request
  def current_validation_request
    validation_requests.where(status: ['pending', 'in_progress']).order(created_at: :desc).first
  end

  # Check if validation is pending
  def validation_pending?
    current_validation_request&.pending?
  end

  # Check if validated
  def validated?
    last_validation = validation_requests.where(status: 'approved').order(created_at: :desc).first
    last_validation.present? && last_validation.created_at > (updated_at || created_at)
  end

  # Check if rejected
  def validation_rejected?
    current_validation_request&.rejected?
  end

  # Get validation status
  def validation_status
    return 'none' unless validation_requests.any?
    current_validation_request&.status || 'completed'
  end

  # Can user validate this item?
  def can_be_validated_by?(user)
    return false unless validation_pending?
    
    document_validations
      .joins(:validation_request)
      .where(validation_requests: { status: ['pending', 'in_progress'] })
      .where(validator: user, status: 'pending')
      .exists?
  end

  # Validate by user
  def validate_by!(user, approved:, comment: nil)
    validation = document_validations
      .joins(:validation_request)
      .where(validation_requests: { status: ['pending', 'in_progress'] })
      .find_by!(validator: user, status: 'pending')
    
    validation.update!(
      status: approved ? 'approved' : 'rejected',
      comment: comment,
      validated_at: Time.current
    )
    
    # Check if validation request can be completed
    validation.validation_request.check_completion!
  end

  # Get validation history
  def validation_history
    validation_requests.includes(:requester, document_validations: :validator).order(created_at: :desc)
  end

  # Get validators for current request
  def current_validators
    return [] unless current_validation_request
    
    current_validation_request.document_validations.includes(:validator)
  end

  # Validation progress percentage
  def validation_progress
    return 0 unless current_validation_request
    
    total = current_validation_request.document_validations.count
    completed = current_validation_request.document_validations.where.not(status: 'pending').count
    
    return 0 if total.zero?
    ((completed.to_f / total) * 100).round
  end

  # Cancel validation request
  def cancel_validation!(cancelled_by:, reason: nil)
    return false unless validation_pending?
    
    current_validation_request.update!(
      status: 'cancelled',
      cancelled_by: cancelled_by,
      cancelled_at: Time.current,
      cancellation_reason: reason
    )
  end
end