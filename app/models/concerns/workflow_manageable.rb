module WorkflowManageable
  extend ActiveSupport::Concern

  included do
    has_many :workflow_steps, class_name: 'ProjectWorkflowStep', as: :workflowable, dependent: :destroy
    has_many :workflow_transitions, class_name: 'ProjectWorkflowTransition', as: :workflowable, dependent: :destroy
    
    validates :status, presence: true
    
    scope :with_status, ->(status) { where(status: status) }
    scope :pending, -> { where(status: 'pending') }
    scope :in_progress, -> { where(status: 'in_progress') }
    scope :completed, -> { where(status: 'completed') }
    scope :cancelled, -> { where(status: 'cancelled') }
  end

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

  def can_transition_to?(new_status)
    case status
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
    
    old_status = status
    
    transaction do
      update!(status: new_status)
      
      workflow_transitions.create!(
        from_status: old_status,
        to_status: new_status,
        user: user,
        comment: comment,
        transitioned_at: Time.current
      )
      
      # Trigger callbacks
      send("on_transition_to_#{new_status}") if respond_to?("on_transition_to_#{new_status}", true)
    end
    
    true
  rescue => e
    errors.add(:status, "Impossible de changer le statut: #{e.message}")
    false
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
      transition_to!('completed', user: user, comment: 'Toutes les étapes sont terminées')
    end
  end

  private

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