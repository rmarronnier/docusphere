class Authorization < ApplicationRecord
  belongs_to :authorizable, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :user_group, optional: true
  
  validates :permission_type, presence: true, inclusion: { in: %w[read write admin] }
  validate :user_or_group_present
  validates :user_id, uniqueness: { scope: [:authorizable_type, :authorizable_id, :permission_type] }, if: :user_id?
  validates :user_group_id, uniqueness: { scope: [:authorizable_type, :authorizable_id, :permission_type] }, if: :user_group_id?
  
  scope :for_user, ->(user) { where(user: user) }
  scope :for_group, ->(group) { where(user_group: group) }
  scope :with_permission, ->(permission) { where(permission_type: permission) }
  
  private
  
  def user_or_group_present
    errors.add(:base, 'User or UserGroup must be present') unless user.present? || user_group.present?
  end
end
