module Authorizable
  extend ActiveSupport::Concern

  included do
    has_many :authorizations, as: :authorizable, dependent: :destroy
    
    scope :readable_by, ->(user) {
      joins(:authorizations).where(
        authorizations: { 
          user: user, 
          permission_type: ['read', 'write', 'admin'] 
        }
      ).or(
        joins(:authorizations).joins('JOIN user_group_memberships ON authorizations.user_group_id = user_group_memberships.user_group_id')
                               .where(
                                 user_group_memberships: { user: user },
                                 authorizations: { permission_type: ['read', 'write', 'admin'] }
                               )
      )
    }
    
    scope :writable_by, ->(user) {
      joins(:authorizations).where(
        authorizations: { 
          user: user, 
          permission_type: ['write', 'admin'] 
        }
      ).or(
        joins(:authorizations).joins('JOIN user_group_memberships ON authorizations.user_group_id = user_group_memberships.user_group_id')
                               .where(
                                 user_group_memberships: { user: user },
                                 authorizations: { permission_type: ['write', 'admin'] }
                               )
      )
    }
  end

  def readable_by?(user)
    return true if user.super_admin?
    return true if owned_by?(user)
    
    authorizations.exists?(user: user, permission_type: ['read', 'write', 'admin']) ||
      authorizations.joins(:user_group)
                   .joins('JOIN user_group_memberships ON user_groups.id = user_group_memberships.user_group_id')
                   .exists?(
                     user_group_memberships: { user_id: user.id },
                     permission_type: ['read', 'write', 'admin']
                   )
  end

  def writable_by?(user)
    return true if user.super_admin?
    return true if owned_by?(user)
    
    authorizations.exists?(user: user, permission_type: ['write', 'admin']) ||
      authorizations.joins(:user_group)
                   .joins('JOIN user_group_memberships ON user_groups.id = user_group_memberships.user_group_id')
                   .exists?(
                     user_group_memberships: { user_id: user.id },
                     permission_type: ['write', 'admin']
                   )
  end

  def admin_by?(user)
    return true if user.super_admin?
    return true if owned_by?(user)
    
    authorizations.exists?(user: user, permission_type: 'admin') ||
      authorizations.joins(:user_group)
                   .joins('JOIN user_group_memberships ON user_groups.id = user_group_memberships.user_group_id')
                   .exists?(
                     user_group_memberships: { user_id: user.id },
                     permission_type: 'admin'
                   )
  end

  def grant_permission(subject, permission_type)
    case subject
    when User
      authorizations.find_or_create_by(user: subject, permission_type: permission_type)
    when UserGroup
      authorizations.find_or_create_by(user_group: subject, permission_type: permission_type)
    else
      raise ArgumentError, "Subject must be a User or UserGroup"
    end
  end

  def revoke_permission(subject, permission_type = nil)
    scope = case subject
            when User
              authorizations.where(user: subject)
            when UserGroup
              authorizations.where(user_group: subject)
            else
              raise ArgumentError, "Subject must be a User or UserGroup"
            end
    
    scope = scope.where(permission_type: permission_type) if permission_type
    scope.destroy_all
  end

  def permissions_for(user)
    # Direct user permissions
    direct_permissions = authorizations.where(user: user).pluck(:permission_type)
    
    # Group permissions
    group_permissions = authorizations.joins(:user_group)
                                     .joins('JOIN user_group_memberships ON user_groups.id = user_group_memberships.user_group_id')
                                     .where(user_group_memberships: { user: user })
                                     .pluck(:permission_type)
    
    (direct_permissions + group_permissions).uniq
  end

  def authorized_users(permission_type = nil)
    scope = User.joins(:authorizations)
                .where(authorizations: { authorizable: self })
    
    scope = scope.where(authorizations: { permission_type: permission_type }) if permission_type
    
    scope.distinct
  end

  def authorized_groups(permission_type = nil)
    scope = UserGroup.joins(:authorizations)
                     .where(authorizations: { authorizable: self })
    
    scope = scope.where(authorizations: { permission_type: permission_type }) if permission_type
    
    scope.distinct
  end

  private

  def owned_by?(user)
    # Check if owned by user (general case)
    return true if respond_to?(:user) && self.user == user
    # Check if user is project manager (for Immo::Promo models)
    return true if respond_to?(:project_manager) && self.project_manager == user
    false
  end
end