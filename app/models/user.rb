class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # Devise modules will be added after devise:install
  
  belongs_to :organization
  has_many :documents, dependent: :destroy
  has_many :baskets, dependent: :destroy
  has_many :workflows, dependent: :destroy
  has_many :user_group_memberships, dependent: :destroy
  has_many :user_groups, through: :user_group_memberships
  has_many :notifications, dependent: :destroy
  has_many :search_queries, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: %w[user manager admin super_admin] }
  
  serialize :permissions, coder: JSON
  
  enum role: { user: 'user', manager: 'manager', admin: 'admin', super_admin: 'super_admin' }
  
  before_validation :set_default_role, on: :create
  before_validation :set_default_permissions, on: :create

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    full_name.presence || email
  end
  
  def has_permission?(permission)
    return true if super_admin?
    (permissions || []).include?(permission.to_s) || 
      user_group_memberships.any? { |membership| membership.has_permission?(permission) }
  end
  
  def add_permission(permission)
    current_permissions = permissions || []
    self.permissions = (current_permissions + [permission.to_s]).uniq
  end
  
  def remove_permission(permission)
    current_permissions = permissions || []
    self.permissions = current_permissions - [permission.to_s]
  end
  
  def admin_of_group?(group)
    user_group_memberships.find_by(user_group: group)&.admin?
  end
  
  def member_of_group?(group)
    user_groups.include?(group)
  end
  
  private
  
  def set_default_role
    self.role ||= 'user'
  end
  
  def set_default_permissions
    self.permissions ||= []
  end
end