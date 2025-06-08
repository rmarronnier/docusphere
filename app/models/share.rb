class Share < ApplicationRecord
  belongs_to :shareable, polymorphic: true
  belongs_to :shared_with, class_name: 'User', optional: true
  belongs_to :shared_with_group, class_name: 'UserGroup', optional: true
  belongs_to :shared_by, class_name: 'User'
  
  validates :access_level, inclusion: { in: %w[read write admin] }
  validate :shared_with_presence
  
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  
  private
  
  def shared_with_presence
    unless shared_with.present? || shared_with_group.present? || email.present?
      errors.add(:base, 'Must specify either a user, group, or email to share with')
    end
  end
end
