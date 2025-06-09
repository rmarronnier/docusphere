class UserNotificationPreference < ApplicationRecord
  belongs_to :user
  
  validates :notification_type, presence: true
  validates :notification_type, uniqueness: { scope: :user_id }
  validates :notification_type, inclusion: { in: Notification.notification_types.keys }
  
  # Delivery methods
  enum delivery_method: {
    in_app: 'in_app',
    email: 'email',
    both: 'both',
    disabled: 'disabled'
  }
  
  # Frequency for non-urgent notifications
  enum frequency: {
    immediate: 'immediate',
    daily_digest: 'daily_digest',
    weekly_digest: 'weekly_digest',
    disabled_frequency: 'disabled_frequency'
  }
  
  scope :enabled, -> { where.not(delivery_method: 'disabled') }
  scope :for_notification_type, ->(type) { where(notification_type: type) }
  scope :for_category, ->(category) { 
    where(notification_type: Notification.notification_types_by_category(category)) 
  }
  scope :email_enabled, -> { where(delivery_method: ['email', 'both']) }
  scope :in_app_enabled, -> { where(delivery_method: ['in_app', 'both']) }
  
  def self.default_preferences_for_user(user)
    Notification.notification_types.keys.map do |type|
      {
        user: user,
        notification_type: type,
        delivery_method: default_delivery_method_for(type),
        frequency: default_frequency_for(type),
        enabled: default_enabled_for(type)
      }
    end
  end
  
  def self.create_default_preferences_for_user!(user)
    return if user.user_notification_preferences.exists?
    
    preferences = default_preferences_for_user(user)
    create!(preferences)
  end
  
  def self.default_delivery_method_for(notification_type)
    case notification_type.to_sym
    when :system_announcement, :maintenance_scheduled
      'both'
    when *Notification.urgent_types.map(&:to_sym)
      'both'
    when :document_shared, :authorization_granted
      'both'
    else
      'in_app'
    end
  end
  
  def self.default_frequency_for(notification_type)
    case notification_type.to_sym
    when *Notification.urgent_types.map(&:to_sym)
      'immediate'
    when :system_announcement, :maintenance_scheduled
      'immediate'
    when :document_validation_requested, :project_task_assigned, :stakeholder_assigned
      'immediate'
    else
      'daily_digest'
    end
  end
  
  def self.default_enabled_for(notification_type)
    # All notifications are enabled by default
    true
  end
  
  def urgent_notification?
    Notification.urgent_types.include?(notification_type)
  end
  
  def category
    Notification.categories.find do |cat|
      Notification.notification_types_by_category(cat).include?(notification_type)
    end
  end
  
  def should_deliver_in_app?
    enabled? && (delivery_method.in?(['in_app', 'both']))
  end
  
  def should_deliver_email?
    enabled? && (delivery_method.in?(['email', 'both']))
  end
  
  def should_deliver_immediately?
    urgent_notification? || frequency == 'immediate'
  end
  
  def display_name
    I18n.t("notification_types.#{notification_type}", 
           default: notification_type.humanize)
  end
  
  def description
    I18n.t("notification_descriptions.#{notification_type}", 
           default: "Notifications for #{notification_type.humanize.downcase}")
  end
end