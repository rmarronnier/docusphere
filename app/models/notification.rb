class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true
  
  validates :notification_type, presence: true
  validates :title, presence: true
  
  enum notification_type: {
    document_validation_requested: 'document_validation_requested',
    document_validation_approved: 'document_validation_approved', 
    document_validation_rejected: 'document_validation_rejected',
    document_shared: 'document_shared',
    authorization_granted: 'authorization_granted',
    authorization_revoked: 'authorization_revoked',
    document_processing_completed: 'document_processing_completed',
    document_processing_failed: 'document_processing_failed',
    system_announcement: 'system_announcement'
  }
  
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :for_user, ->(user) { where(user: user) }
  
  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
  
  def read?
    read_at.present?
  end
  
  def unread?
    !read?
  end
  
  def icon
    case notification_type.to_sym
    when :document_validation_requested
      'clipboard-check'
    when :document_validation_approved
      'check-circle'
    when :document_validation_rejected
      'x-circle'
    when :document_shared
      'share'
    when :authorization_granted
      'key'
    when :authorization_revoked
      'lock'
    when :document_processing_completed
      'check'
    when :document_processing_failed
      'alert-triangle'
    when :system_announcement
      'bell'
    else
      'info'
    end
  end
  
  def color_class
    case notification_type.to_sym
    when :document_validation_approved, :document_processing_completed
      'text-green-600'
    when :document_validation_rejected, :authorization_revoked, :document_processing_failed
      'text-red-600'
    when :document_validation_requested, :document_shared
      'text-blue-600'
    when :authorization_granted
      'text-purple-600'
    when :system_announcement
      'text-yellow-600'
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
  
  def time_ago
    return "à l'instant" if created_at > 1.minute.ago
    return "il y a #{time_ago_in_words(created_at)}"
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