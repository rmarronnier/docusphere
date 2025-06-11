# Concern for document locking functionality
module Documents::Lockable
  extend ActiveSupport::Concern

  included do
    belongs_to :locked_by, class_name: 'User', foreign_key: 'locked_by_id', optional: true
    
    scope :locked, -> { where.not(locked_by_id: nil) }
    scope :unlocked, -> { where(locked_by_id: nil) }
    scope :with_expired_locks, -> { locked.where('unlock_scheduled_at <= ?', Time.current) }
  end

  # Lock the document
  def lock_document!(user, reason: nil, scheduled_unlock: nil)
    return false unless can_lock?(user)
    
    self.locked_by = user
    self.lock_reason = reason
    self.unlock_scheduled_at = scheduled_unlock
    
    lock! # AASM event
  end

  # Unlock the document
  def unlock_document!(user)
    return false unless can_unlock?(user)
    
    unlock! # AASM event
  end

  # Check if user can lock
  def can_lock?(user)
    return false unless user
    return false if locked?
    
    # Owner can lock
    return true if uploaded_by == user
    
    # Admin can lock
    return true if admin_by?(user)
    
    # Users with write permission can lock
    writable_by?(user)
  end

  # Check if user can unlock
  def can_unlock?(user)
    return false unless user
    return false unless locked?
    
    # The user who locked can unlock
    return true if locked_by == user
    
    # Owner can unlock
    return true if uploaded_by == user
    
    # Admin can unlock
    admin_by?(user)
  end

  # Check if locked by specific user
  def locked_by_user?(user)
    locked? && locked_by == user
  end

  # Check if lock has expired
  def lock_expired?
    return false unless locked?
    return false unless unlock_scheduled_at
    
    unlock_scheduled_at <= Time.current
  end

  # Check if editable by user (considering lock status)
  def editable_by?(user)
    return false if locked? && !locked_by_user?(user)
    
    writable_by?(user)
  end

  # Auto-unlock expired locks
  def self.unlock_expired_locks!
    with_expired_locks.find_each do |document|
      document.unlock!
      Rails.logger.info "Auto-unlocked document ##{document.id} - lock expired"
    end
  end
end