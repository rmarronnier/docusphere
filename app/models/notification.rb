class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true
  
  validates :notification_type, presence: true
  
  scope :unread, -> { where(is_read: false) }
  scope :recent, -> { order(created_at: :desc) }
  
  def mark_as_read!
    update!(is_read: true)
  end
end