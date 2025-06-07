class UserGroupMembership < ApplicationRecord
  belongs_to :user
  belongs_to :user_group
  
  validates :user_id, uniqueness: { scope: :user_group_id }
  validates :role, presence: true, inclusion: { in: %w[member admin] }
  
  serialize :permissions, coder: JSON
  
  enum role: { member: 'member', admin: 'admin' }
  
  scope :admins, -> { where(role: 'admin') }
  scope :members, -> { where(role: 'member') }
  
  def has_permission?(permission)
    (permissions || []).include?(permission.to_s)
  end
  
  def add_permission(permission)
    current_permissions = permissions || []
    self.permissions = (current_permissions + [permission.to_s]).uniq
  end
  
  def remove_permission(permission)
    current_permissions = permissions || []
    self.permissions = current_permissions - [permission.to_s]
  end
end
