# Concern for adding validation workflow capabilities to models
module Validatable
  extend ActiveSupport::Concern

  included do
    # Only add associations if they don't already exist
    unless reflect_on_association(:validation_requests)
      if self.name == 'Document'
        # Document has direct foreign key relationship
        has_many :validation_requests, foreign_key: :document_id, dependent: :destroy
      else
        # Other models might use polymorphic association in the future
        has_many :validation_requests, as: :validatable, dependent: :destroy
      end
    end
    
    unless reflect_on_association(:document_validations)
      if self.name == 'Document'
        # Document has direct foreign key relationship
        has_many :document_validations, foreign_key: :document_id, dependent: :destroy
      else
        # Other models might use polymorphic association in the future
        has_many :document_validations, as: :validatable, dependent: :destroy
      end
    end
    
    unless reflect_on_association(:validators)
      has_many :validators, through: :document_validations, source: :validator
    end
    
    scope :pending_validation, -> { joins(:validation_requests).where(validation_requests: { status: 'pending' }) }
    scope :validated, -> { joins(:validation_requests).where(validation_requests: { status: 'approved' }) }
    scope :rejected, -> { joins(:validation_requests).where(validation_requests: { status: 'rejected' }) }
  end

  # Request validation from specific validators
  def request_validation(requester:, validators:, min_validations: 1, due_date: nil, notes: nil)
    return false if validation_pending?
    
    validation_request_params = {
      requester: requester,
      min_validations: min_validations,
      due_date: due_date,
      description: notes,
      status: 'pending'
    }
    
    # Add document_id for Document model
    validation_request_params[:document_id] = self.id if self.is_a?(Document)
    
    validation_request = validation_requests.create!(validation_request_params)
    
    validators.each do |validator|
      validation_params = {
        validation_request: validation_request,
        validator: validator,
        status: 'pending'
      }
      
      # Add document_id for Document model
      validation_params[:document_id] = self.id if self.is_a?(Document)
      
      document_validations.create!(validation_params)
    end
    
    validation_request
  end

  # Current active validation request
  def current_validation_request
    # Check for pending or rejected first, then fallback to active scope if available
    validation_requests.where(status: ['pending', 'rejected']).order(created_at: :desc).first ||
      (validation_requests.respond_to?(:active) ? validation_requests.active.last : nil)
  end

  # Check if validation is pending
  def validation_pending?
    current_validation_request&.pending? || false
  end

  # Check if validated
  def validated?
    last_validation = validation_requests.where(status: 'approved').order(created_at: :desc).first
    last_validation.present? && last_validation.created_at > (updated_at || created_at)
  end

  # Check if rejected
  def validation_rejected?
    current_validation_request&.rejected? || false
  end

  # Get validation status
  def validation_status
    return 'none' unless validation_requests.any?
    current_validation_request&.status || validation_requests.order(created_at: :desc).first.status
  end

  # Can user validate this item?
  def can_be_validated_by?(user)
    return false unless validation_pending?
    
    document_validations
      .joins(:validation_request)
      .where(validation_requests: { status: 'pending' })
      .where(validator: user, status: 'pending')
      .exists?
  end

  # Validate by user
  def validate_by!(user, approved:, comment: nil)
    # Find validation for current pending request
    current_request = current_validation_request
    return false unless current_request
    
    validation = document_validations
      .where(validation_request: current_request)
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
    
    # Since 'cancelled' status doesn't exist, we reject it instead
    current_validation_request.update!(
      status: 'rejected',
      completed_at: Time.current
    )
  end
end