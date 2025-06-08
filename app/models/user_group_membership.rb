class UserGroupMembership < ApplicationRecord
  belongs_to :user
  belongs_to :user_group
  
  validates :user_id, uniqueness: { scope: :user_group_id }
  validates :role, presence: true, inclusion: { in: %w[member admin] }
  
  enum role: { member: 'member', admin: 'admin' }
  
  scope :admins, -> { where(role: 'admin') }
  scope :members, -> { where(role: 'member') }
  
  def has_permission?(permission)
    # Check permissions from the user group
    (user_group.permissions || {}).key?(permission.to_s) && user_group.permissions[permission.to_s]
  end
end
