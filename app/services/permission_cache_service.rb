class PermissionCacheService
  CACHE_TTL = 5.minutes
  CACHE_PREFIX = 'permissions'
  
  class << self
    def authorized_for?(authorizable, user, permission_level)
      return false unless user && authorizable
      
      cache_key = build_key(authorizable, user, permission_level)
      
      # Try to get from cache
      cached_value = Rails.cache.read(cache_key)
      return cached_value unless cached_value.nil?
      
      # Calculate permission
      result = calculate_permission(authorizable, user, permission_level)
      
      # Store in cache
      Rails.cache.write(cache_key, result, expires_in: CACHE_TTL)
      
      result
    end
    
    def clear_for_user(user)
      return unless user
      
      # Redis cache store doesn't support delete_matched well
      # We need to use a different approach
      if Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
        redis = Rails.cache.redis
        pattern = "#{CACHE_PREFIX}:*:user:#{user.id}:*"
        
        cursor = 0
        loop do
          cursor, keys = redis.scan(cursor, match: pattern, count: 100)
          redis.del(*keys) unless keys.empty?
          break if cursor == "0"
        end
      else
        Rails.cache.delete_matched("#{CACHE_PREFIX}:*:user:#{user.id}:*")
      end
    end
    
    def clear_for_authorizable(authorizable)
      return unless authorizable
      
      if Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
        redis = Rails.cache.redis
        pattern = "#{CACHE_PREFIX}:#{authorizable.class.name}:#{authorizable.id}:*"
        
        cursor = 0
        loop do
          cursor, keys = redis.scan(cursor, match: pattern, count: 100)
          redis.del(*keys) unless keys.empty?
          break if cursor == "0"
        end
      else
        Rails.cache.delete_matched("#{CACHE_PREFIX}:#{authorizable.class.name}:#{authorizable.id}:*")
      end
    end
    
    def clear_all
      if Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
        redis = Rails.cache.redis
        pattern = "#{CACHE_PREFIX}:*"
        
        cursor = 0
        loop do
          cursor, keys = redis.scan(cursor, match: pattern, count: 100)
          redis.del(*keys) unless keys.empty?
          break if cursor == "0"
        end
      else
        Rails.cache.delete_matched("#{CACHE_PREFIX}:*")
      end
    end
    
    private
    
    def build_key(authorizable, user, permission_level)
      "#{CACHE_PREFIX}:#{authorizable.class.name}:#{authorizable.id}:user:#{user.id}:#{permission_level}"
    end
    
    def calculate_permission(authorizable, user, permission_level)
      # Direct user permissions (active only)
      user_authorized = authorizable.active_authorizations
                                   .for_user(user)
                                   .with_permission(permission_level)
                                   .exists?
      return true if user_authorized
      
      # Group permissions (active only)
      user_group_ids = user.user_group_memberships.pluck(:user_group_id)
      return false if user_group_ids.empty?
      
      authorizable.active_authorizations
                  .where(user_group_id: user_group_ids)
                  .with_permission(permission_level)
                  .exists?
    end
  end
end