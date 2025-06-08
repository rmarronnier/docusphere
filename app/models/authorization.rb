class Authorization < ApplicationRecord
  belongs_to :authorizable, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :user_group, optional: true
  belongs_to :granted_by, class_name: 'User', optional: true
  belongs_to :revoked_by, class_name: 'User', optional: true
  
  validates :permission_level, presence: true, inclusion: { in: %w[read write admin validate] }
  validate :user_or_group_present
  validates :user_id, uniqueness: { scope: [:authorizable_type, :authorizable_id, :permission_level] }, if: :user_id?
  validates :user_group_id, uniqueness: { scope: [:authorizable_type, :authorizable_id, :permission_level] }, if: :user_group_id?
  validate :expiry_date_in_future, if: :expires_at?
  
  scope :for_user, ->(user) { where(user: user) }
  scope :for_group, ->(group) { where(user_group: group) }
  scope :with_permission, ->(permission) { where(permission_level: permission) }
  scope :active, -> { where(revoked_at: nil).where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :granted_by_user, ->(user) { where(granted_by: user) }
  
  before_create :set_granted_at
  
  def active?
    !revoked? && !expired?
  end
  
  def expired?
    expires_at.present? && expires_at <= Time.current
  end
  
  def revoked?
    revoked_at.present?
  end
  
  def revoke!(revoked_by_user, comment: nil)
    update!(
      revoked_at: Time.current,
      revoked_by: revoked_by_user,
      comment: [self.comment, comment].compact.join("\n")
    )
  end
  
  def extend_expiry!(new_expiry_date, extended_by_user, comment: nil)
    update!(
      expires_at: new_expiry_date,
      comment: [self.comment, comment].compact.join("\n")
    )
    
    # Log extension
    Rails.logger.info "Authorization #{id} extended to #{new_expiry_date} by #{extended_by_user.email}"
  end
  
  def grant_info
    granted_info = "Accordé"
    granted_info += " par #{granted_by.full_name}" if granted_by.present?
    granted_info += " le #{I18n.l(granted_at, format: :short)}" if granted_at.present?
    granted_info
  end
  
  def status_info
    return "Révoqué le #{I18n.l(revoked_at, format: :short)}" if revoked?
    return "Expiré le #{I18n.l(expires_at, format: :short)}" if expired?
    
    if expires_at.present?
      "Actif jusqu'au #{I18n.l(expires_at, format: :short)}"
    else
      "Actif (permanent)"
    end
  end
  
  private
  
  def user_or_group_present
    errors.add(:base, 'User or UserGroup must be present') unless user.present? || user_group.present?
  end
  
  def expiry_date_in_future
    return unless expires_at.present?
    
    errors.add(:expires_at, 'must be in the future') if expires_at <= Time.current
  end
  
  def set_granted_at
    self.granted_at ||= Time.current
  end
end
