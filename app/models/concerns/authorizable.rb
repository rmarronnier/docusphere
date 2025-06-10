module Authorizable
  extend ActiveSupport::Concern

  included do
    include Ownership
    has_many :authorizations, as: :authorizable, dependent: :destroy
    has_many :active_authorizations, -> { active }, as: :authorizable, class_name: 'Authorization'
    
    scope :readable_by, ->(user) {
      # Get IDs of items user can read directly
      direct_ids = joins(:active_authorizations)
        .where(authorizations: { 
          user_id: user.id, 
          permission_level: ['read', 'write', 'admin'] 
        })
        .pluck(:id)
      
      # Get IDs of items user can read through groups
      group_ids = joins(active_authorizations: { user_group: :users })
        .where(users: { id: user.id })
        .where(authorizations: { permission_level: ['read', 'write', 'admin'] })
        .pluck(:id)
      
      # Return items with either direct or group permission
      where(id: (direct_ids + group_ids).uniq)
    }
    
    scope :writable_by, ->(user) {
      # Get IDs of items user can write directly
      direct_ids = joins(:active_authorizations)
        .where(authorizations: { 
          user_id: user.id, 
          permission_level: ['write', 'admin'] 
        })
        .pluck(:id)
      
      # Get IDs of items user can write through groups
      group_ids = joins(active_authorizations: { user_group: :users })
        .where(users: { id: user.id })
        .where(authorizations: { permission_level: ['write', 'admin'] })
        .pluck(:id)
      
      # Return items with either direct or group permission
      where(id: (direct_ids + group_ids).uniq)
    }
  end

  def authorize_user(user, permission_level, granted_by: nil, expires_at: nil, comment: nil)
    authorization = active_authorizations.create!(
      user: user, 
      permission_level: permission_level,
      granted_by: granted_by,
      expires_at: expires_at,
      comment: comment
    )
    
    # Clear cache for this user and authorizable
    PermissionCacheService.clear_for_user(user)
    
    authorization
  end
  
  def authorize_group(user_group, permission_level, granted_by: nil, expires_at: nil, comment: nil)
    authorization = active_authorizations.create!(
      user_group: user_group, 
      permission_level: permission_level,
      granted_by: granted_by,
      expires_at: expires_at,
      comment: comment
    )
    
    # Clear cache for all users in the group
    user_group.users.each do |user|
      PermissionCacheService.clear_for_user(user)
    end
    
    authorization
  end
  
  def revoke_authorization(user_or_group, permission_level, revoked_by:, comment: nil)
    auth = if user_or_group.is_a?(User)
      active_authorizations.for_user(user_or_group).with_permission(permission_level).first
    else
      active_authorizations.for_group(user_or_group).with_permission(permission_level).first
    end
    
    if auth&.revoke!(revoked_by, comment: comment)
      # Clear cache
      if user_or_group.is_a?(User)
        PermissionCacheService.clear_for_user(user_or_group)
      else
        user_or_group.users.each do |user|
          PermissionCacheService.clear_for_user(user)
        end
      end
    end
    
    auth
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
    
    # Use cache service for performance
    PermissionCacheService.authorized_for?(self, user, permission_level)
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
                                     .where(user_group_memberships: { user_id: user.id })
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

end