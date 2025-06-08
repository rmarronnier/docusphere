class DocumentShare < ApplicationRecord
  belongs_to :document
  belongs_to :shared_by, class_name: 'User'
  belongs_to :shared_with, class_name: 'User', optional: true
  
  validates :access_level, inclusion: { in: %w[read write admin] }
  validates :email, presence: true, unless: :shared_with
  validates :shared_with, presence: true, unless: :email
  
  before_create :generate_access_token
  
  scope :active, -> { where(is_active: true).where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  
  def expired?
    expires_at.present? && expires_at <= Time.current
  end
  
  def active?
    is_active && !expired?
  end
  
  def revoke!
    update!(is_active: false)
  end
  
  private
  
  def generate_access_token
    self.access_token = SecureRandom.urlsafe_base64(32)
  end
end