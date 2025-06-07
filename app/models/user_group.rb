class UserGroup < ApplicationRecord
  belongs_to :organization
  has_many :user_group_memberships, dependent: :destroy
  has_many :users, through: :user_group_memberships
  has_many :authorizations, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { scope: :organization_id }
  
  scope :for_organization, ->(organization) { where(organization: organization) }
  scope :active, -> { where(is_active: true) }
  scope :by_type, ->(type) { where(group_type: type) }
  
  def active?
    is_active != false
  end
  
  def add_user(user, role: 'member')
    user_group_memberships.create(user: user, role: role)
  end
  
  def remove_user(user)
    user_group_memberships.where(user: user).destroy_all
  end
  
  def has_user?(user)
    users.include?(user)
  end
  
  def admin_users
    users.joins(:user_group_memberships).where(user_group_memberships: { role: 'admin' })
  end
  
  def member_count
    users.count
  end
end
