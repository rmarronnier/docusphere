class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true
  
  validates :notification_type, presence: true
  validates :title, presence: true
  
  enum notification_type: {
    # Document notifications
    document_validation_requested: 'document_validation_requested',
    document_validation_approved: 'document_validation_approved', 
    document_validation_rejected: 'document_validation_rejected',
    document_shared: 'document_shared',
    document_processing_completed: 'document_processing_completed',
    document_processing_failed: 'document_processing_failed',
    
    # Authorization notifications
    authorization_granted: 'authorization_granted',
    authorization_revoked: 'authorization_revoked',
    
    # ImmoPromo Project notifications
    project_created: 'project_created',
    project_updated: 'project_updated',
    project_phase_completed: 'project_phase_completed',
    project_task_assigned: 'project_task_assigned',
    project_task_completed: 'project_task_completed',
    project_task_overdue: 'project_task_overdue',
    project_milestone_reached: 'project_milestone_reached',
    project_deadline_approaching: 'project_deadline_approaching',
    
    # ImmoPromo Stakeholder notifications
    stakeholder_assigned: 'stakeholder_assigned',
    stakeholder_approved: 'stakeholder_approved',
    stakeholder_rejected: 'stakeholder_rejected',
    stakeholder_certification_expiring: 'stakeholder_certification_expiring',
    
    # ImmoPromo Permit notifications
    permit_submitted: 'permit_submitted',
    permit_approved: 'permit_approved',
    permit_rejected: 'permit_rejected',
    permit_deadline_approaching: 'permit_deadline_approaching',
    permit_condition_fulfilled: 'permit_condition_fulfilled',
    
    # ImmoPromo Budget notifications
    budget_alert: 'budget_alert',
    budget_exceeded: 'budget_exceeded',
    budget_adjustment_requested: 'budget_adjustment_requested',
    budget_adjustment_approved: 'budget_adjustment_approved',
    
    # ImmoPromo Risk notifications
    risk_identified: 'risk_identified',
    risk_escalated: 'risk_escalated',
    risk_mitigation_required: 'risk_mitigation_required',
    risk_resolved: 'risk_resolved',
    
    # System notifications
    system_announcement: 'system_announcement',
    maintenance_scheduled: 'maintenance_scheduled'
  }
  
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_category, ->(category) { category.present? ? where(notification_type: notification_types_by_category(category)) : all }
  scope :urgent, -> { where(notification_type: urgent_types) }
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', Time.current.beginning_of_week) }
  
  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
  
  def read?
    read_at.present?
  end
  
  def unread?
    !read?
  end

  def urgent?
    self.class.urgent_types.include?(notification_type)
  end

  def category
    self.class.categories.find do |cat|
      self.class.notification_types_by_category(cat).include?(notification_type)
    end
  end

  def immo_promo_related?
    %w[projects stakeholders permits budgets risks].include?(category)
  end
  
  def icon
    case notification_type.to_sym
    when :document_validation_requested
      'clipboard-check'
    when :document_validation_approved, :document_processing_completed
      'check-circle'
    when :document_validation_rejected, :document_processing_failed
      'x-circle'
    when :document_shared
      'share'
    when :authorization_granted
      'key'
    when :authorization_revoked
      'lock'
    when :project_created, :project_updated
      'folder-plus'
    when :project_phase_completed, :project_task_completed, :project_milestone_reached
      'check-circle'
    when :project_task_assigned, :stakeholder_assigned
      'user-check'
    when :project_task_overdue, :project_deadline_approaching
      'clock'
    when :stakeholder_approved, :permit_approved, :budget_adjustment_approved
      'check-circle'
    when :stakeholder_rejected, :permit_rejected
      'x-circle'
    when :stakeholder_certification_expiring, :permit_deadline_approaching
      'alert-triangle'
    when :permit_submitted
      'file-text'
    when :permit_condition_fulfilled
      'check-square'
    when :budget_alert, :budget_exceeded
      'alert-triangle'
    when :budget_adjustment_requested
      'dollar-sign'
    when :risk_identified, :risk_escalated, :risk_mitigation_required
      'alert-triangle'
    when :risk_resolved
      'shield-check'
    when :system_announcement
      'bell'
    when :maintenance_scheduled
      'tool'
    else
      'info'
    end
  end
  
  def color_class
    case notification_type.to_sym
    when :document_validation_approved, :document_processing_completed,
         :project_phase_completed, :project_task_completed, :project_milestone_reached,
         :stakeholder_approved, :permit_approved, :permit_condition_fulfilled,
         :budget_adjustment_approved, :risk_resolved
      'text-green-600'
    when :document_validation_rejected, :authorization_revoked, :document_processing_failed,
         :stakeholder_rejected, :permit_rejected, :budget_exceeded
      'text-red-600'
    when :document_validation_requested, :document_shared,
         :project_created, :project_updated, :permit_submitted
      'text-blue-600'
    when :authorization_granted, :project_task_assigned, :stakeholder_assigned
      'text-purple-600'
    when :system_announcement, :project_task_overdue, :project_deadline_approaching,
         :stakeholder_certification_expiring, :permit_deadline_approaching,
         :budget_alert, :risk_identified, :risk_escalated, :risk_mitigation_required,
         :maintenance_scheduled
      'text-yellow-600'
    when :budget_adjustment_requested
      'text-orange-600'
    else
      'text-gray-600'
    end
  end
  
  def self.notify_user(user, type, title, message, notifiable: nil, data: {})
    create!(
      user: user,
      notification_type: type,
      title: title,
      message: message,
      notifiable: notifiable,
      data: data
    )
  end
  
  def self.mark_all_as_read_for(user)
    unread.for_user(user).update_all(read_at: Time.current)
  end

  def self.notification_types_by_category(category)
    case category.to_sym
    when :documents
      %w[document_validation_requested document_validation_approved document_validation_rejected 
         document_shared document_processing_completed document_processing_failed]
    when :projects
      %w[project_created project_updated project_phase_completed project_task_assigned 
         project_task_completed project_task_overdue project_milestone_reached project_deadline_approaching]
    when :stakeholders
      %w[stakeholder_assigned stakeholder_approved stakeholder_rejected stakeholder_certification_expiring]
    when :permits
      %w[permit_submitted permit_approved permit_rejected permit_deadline_approaching permit_condition_fulfilled]
    when :budgets
      %w[budget_alert budget_exceeded budget_adjustment_requested budget_adjustment_approved]
    when :risks
      %w[risk_identified risk_escalated risk_mitigation_required risk_resolved]
    when :authorization
      %w[authorization_granted authorization_revoked]
    when :system
      %w[system_announcement maintenance_scheduled]
    else
      []
    end
  end

  def self.urgent_types
    %w[project_task_overdue project_deadline_approaching permit_deadline_approaching 
       stakeholder_certification_expiring budget_exceeded risk_escalated 
       document_processing_failed maintenance_scheduled]
  end

  def self.categories
    %w[documents projects stakeholders permits budgets risks authorization system]
  end
  
  def time_ago
    return "à l'instant" if created_at > 1.minute.ago
    return "il y a #{ApplicationController.helpers.time_ago_in_words(created_at)}"
  end
  
  def formatted_data
    return {} unless data.present?
    
    case data
    when String
      JSON.parse(data) rescue {}
    when Hash
      data
    else
      {}
    end
  end
end