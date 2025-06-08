module Authorizable
  extend ActiveSupport::Concern

  included do
    has_many :authorizations, as: :authorizable, dependent: :destroy
    has_many :active_authorizations, -> { active }, as: :authorizable, class_name: 'Authorization'
    
    scope :readable_by, ->(user) {
      joins(:active_authorizations).where(
        authorizations: { 
          user: user, 
          permission_level: ['read', 'write', 'admin'] 
        }
      ).or(
        joins(:active_authorizations).joins('JOIN user_group_memberships ON authorizations.user_group_id = user_group_memberships.user_group_id')
                               .where(
                                 user_group_memberships: { user: user },
                                 authorizations: { permission_level: ['read', 'write', 'admin'] }
                               )
      )
    }
    
    scope :writable_by, ->(user) {
      joins(:active_authorizations).where(
        authorizations: { 
          user: user, 
          permission_level: ['write', 'admin'] 
        }
      ).or(
        joins(:active_authorizations).joins('JOIN user_group_memberships ON authorizations.user_group_id = user_group_memberships.user_group_id')
                               .where(
                                 user_group_memberships: { user: user },
                                 authorizations: { permission_level: ['write', 'admin'] }
                               )
      )
    }
  end

  def authorize_user(user, permission_level, granted_by: nil, expires_at: nil, comment: nil)
    active_authorizations.create!(
      user: user, 
      permission_level: permission_level,
      granted_by: granted_by,
      expires_at: expires_at,
      comment: comment
    )
  end
  
  def authorize_group(user_group, permission_level, granted_by: nil, expires_at: nil, comment: nil)
    active_authorizations.create!(
      user_group: user_group, 
      permission_level: permission_level,
      granted_by: granted_by,
      expires_at: expires_at,
      comment: comment
    )
  end
  
  def revoke_authorization(user_or_group, permission_level, revoked_by:, comment: nil)
    auth = if user_or_group.is_a?(User)
      active_authorizations.for_user(user_or_group).with_permission(permission_level).first
    else
      active_authorizations.for_group(user_or_group).with_permission(permission_level).first
    end
    
    auth&.revoke!(revoked_by, comment: comment)
  end

  def readable_by?(user)
    return true if user.super_admin?
    return true if owned_by?(user)
    
    authorized_for?(user, 'read') || authorized_for?(user, 'write') || authorized_for?(user, 'admin')
  end

  def writable_by?(user)
    return true if user.super_admin?
    return true if owned_by?(user)
    
    authorized_for?(user, 'write') || authorized_for?(user, 'admin')
  end

  def admin_by?(user)
    return true if user.super_admin?
    return true if owned_by?(user)
    
    authorized_for?(user, 'admin')
  end
  
  def can_validate?(user)
    return true if user.super_admin?
    return true if owned_by?(user)
    
    authorized_for?(user, 'validate') || authorized_for?(user, 'admin')
  end
  
  def can_read?(user)
    readable_by?(user)
  end
  
  def can_write?(user)
    writable_by?(user)
  end
  
  def can_admin?(user)
    admin_by?(user)
  end
  
  def authorized_for?(user, permission_level)
    return false unless user
    
    # Check direct user permissions (active only)
    user_authorized = active_authorizations
                       .for_user(user)
                       .with_permission(permission_level)
                       .exists?
    return true if user_authorized
    
    # Check group permissions (active only)
    user_group_ids = user.user_group_memberships.pluck(:user_group_id)
    return false if user_group_ids.empty?
    
    group_authorized = active_authorizations
                        .where(user_group_id: user_group_ids)
                        .with_permission(permission_level)
                        .exists?
    group_authorized
  end

  def grant_permission(subject, permission_level, granted_by: nil, expires_at: nil, comment: nil)
    case subject
    when User
      authorize_user(subject, permission_level, granted_by: granted_by, expires_at: expires_at, comment: comment)
    when UserGroup
      authorize_group(subject, permission_level, granted_by: granted_by, expires_at: expires_at, comment: comment)
    else
      raise ArgumentError, "Subject must be a User or UserGroup"
    end
  end

  def revoke_permission(subject, permission_level, revoked_by:, comment: nil)
    revoke_authorization(subject, permission_level, revoked_by: revoked_by, comment: comment)
  end

  def permissions_for(user)
    # Direct user permissions
    direct_permissions = authorizations.where(user: user).pluck(:permission_level)
    
    # Group permissions
    group_permissions = authorizations.joins(:user_group)
                                     .joins('JOIN user_group_memberships ON user_groups.id = user_group_memberships.user_group_id')
                                     .where(user_group_memberships: { user: user })
                                     .pluck(:permission_level)
    
    (direct_permissions + group_permissions).uniq
  end

  def authorized_users(permission_level = nil)
    scope = User.joins(:authorizations)
                .where(authorizations: { authorizable: self })
    
    scope = scope.where(authorizations: { permission_level: permission_level }) if permission_level
    
    scope.distinct
  end

  def authorized_groups(permission_level = nil)
    scope = UserGroup.joins(:authorizations)
                     .where(authorizations: { authorizable: self })
    
    scope = scope.where(authorizations: { permission_level: permission_level }) if permission_level
    
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