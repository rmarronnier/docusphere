# Concern to add workflow state management to Immo::Promo models
# Works alongside existing status enums
module Immo::Promo::WorkflowStates
  extend ActiveSupport::Concern

  included do
    # Keep existing associations from WorkflowManageable
    has_many :workflow_steps, class_name: 'ProjectWorkflowStep', as: :workflowable, dependent: :destroy
    has_many :workflow_transitions, class_name: 'ProjectWorkflowTransition', as: :workflowable, dependent: :destroy

    # Add workflow-specific scopes using workflow_status column
    scope :with_workflow_status, ->(status) { where(workflow_status: status) }
    scope :workflow_pending, -> { where(workflow_status: 'pending') }
    scope :workflow_in_progress, -> { where(workflow_status: 'in_progress') }
    scope :workflow_completed, -> { where(workflow_status: 'completed') }
    scope :workflow_cancelled, -> { where(workflow_status: 'cancelled') }

    # Callbacks to sync workflow_status with status
    before_save :sync_workflow_status, if: :status_changed?
  end

  # Methods from WorkflowManageable
  def next_steps
    workflow_steps.where(status: 'pending').order(:position)
  end

  def current_step
    workflow_steps.find_by(status: 'in_progress')
  end

  def completed_steps
    workflow_steps.where(status: 'completed').order(:position)
  end

  def progress_percentage
    return 0 if workflow_steps.empty?
    
    completed_count = completed_steps.count
    total_count = workflow_steps.count
    
    (completed_count.to_f / total_count * 100).round(2)
  end

  def add_step(name, description: nil, position: nil, assigned_to: nil)
    position ||= workflow_steps.maximum(:position).to_i + 1
    
    workflow_steps.create!(
      name: name,
      description: description,
      position: position,
      assigned_to: assigned_to,
      status: 'pending'
    )
  end

  def complete_step(step_id, user: nil, comment: nil)
    step = workflow_steps.find(step_id)
    step.complete!(user: user, comment: comment)
    
    # Check if all steps are completed
    if workflow_steps.where.not(status: 'completed').empty?
      update!(status: 'completed') if status != 'completed'
    end
  end

  # Workflow transition methods
  def can_transition_to?(new_status)
    case workflow_status
    when 'pending'
      %w[in_progress cancelled].include?(new_status)
    when 'in_progress'
      %w[completed cancelled].include?(new_status)
    when 'completed'
      false
    when 'cancelled'
      %w[pending in_progress].include?(new_status)
    else
      false
    end
  end

  def transition_to!(new_status, user: nil, comment: nil)
    return false unless can_transition_to?(new_status)
    
    old_status = workflow_status
    
    transaction do
      update!(workflow_status: new_status)
      
      workflow_transitions.create!(
        notes: comment,
        transitioned_by: user,
        transitioned_at: Time.current
      )
      
      # Trigger callbacks
      send("on_transition_to_#{new_status}") if respond_to?("on_transition_to_#{new_status}", true)
    end
    
    true
  rescue => e
    errors.add(:workflow_status, "Impossible de changer le statut: #{e.message}")
    false
  end

  private

  def sync_workflow_status
    self.workflow_status = case status
    when 'pending', 'draft'
      'pending'
    when 'in_progress', 'submitted', 'under_review', 'additional_info_requested', 'on_hold'
      'in_progress'
    when 'completed', 'approved'
      'completed'
    when 'cancelled', 'denied', 'appeal'
      'cancelled'
    else
      workflow_status || 'pending'
    end
  end

  # Callback methods to be overridden in including models
  def on_transition_to_in_progress
    # Override in including models
  end

  def on_transition_to_completed
    # Override in including models
  end

  def on_transition_to_cancelled
    # Override in including models
  end
end