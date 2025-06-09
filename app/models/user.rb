class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # Devise modules will be added after devise:install
  
  belongs_to :organization
  has_many :documents, foreign_key: 'uploaded_by_id', dependent: :destroy
  has_many :baskets, dependent: :destroy
  has_many :user_group_memberships, dependent: :destroy
  has_many :user_groups, through: :user_group_memberships
  has_many :notifications, dependent: :destroy
  has_many :search_queries, dependent: :destroy
  has_many :workflow_submissions, foreign_key: 'submitted_by_id', dependent: :destroy
  has_many :validation_requests, foreign_key: 'requester_id', dependent: :destroy
  has_many :document_validations, foreign_key: 'validator_id', dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: %w[user manager admin super_admin] }
  
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
    perms = permissions || {}
    perms = perms.is_a?(Array) ? perms : perms.keys
    perms.include?(permission.to_s) || 
      user_group_memberships.any? { |membership| membership.has_permission?(permission) }
  end
  
  def add_permission(permission)
    current_permissions = permissions || {}
    if current_permissions.is_a?(Array)
      # Convert array to hash format
      self.permissions = current_permissions.map { |p| [p, true] }.to_h
      self.permissions[permission.to_s] = true
    else
      self.permissions = current_permissions.merge(permission.to_s => true)
    end
  end
  
  def add_permission!(permission)
    add_permission(permission)
    save!
  end
  
  def remove_permission(permission)
    current_permissions = permissions || {}
    if current_permissions.is_a?(Array)
      self.permissions = (current_permissions - [permission.to_s]).map { |p| [p, true] }.to_h
    else
      self.permissions = current_permissions.except(permission.to_s)
    end
  end
  
  def admin_of_group?(group)
    user_group_memberships.find_by(user_group: group)&.admin?
  end
  
  def member_of_group?(group)
    user_groups.include?(group)
  end
  
  # Méthodes pour le module ImmoPromo
  def accessible_projects
    return organization.immo_promo_projects if admin? || super_admin?
    # Pour les utilisateurs standards, filtrer selon leurs permissions
    organization.immo_promo_projects
  end
  
  def can_access_immo_promo?
    has_permission?('immo_promo:access') || admin? || super_admin?
  end
  
  def can_manage_project?(project)
    return true if admin? || super_admin?
    return true if project.project_manager == self
    return false unless project.organization == organization
    
    # Check if user has specific project management permissions
    has_permission?('immo_promo:projects:write') || 
    has_permission?('immo_promo:write') ||
    has_permission?('immo_promo:manage')
  end
  
  
  private
  
  def set_default_role
    self.role ||= 'user'
  end
  
  def set_default_permissions
    self.permissions ||= {}
  end
end