class TreePathCacheService
  CACHE_TTL = 1.hour
  CACHE_PREFIX = 'tree_paths'
  
  class << self
    def path_for(node)
      return [] unless node
      
      cache_key = build_key(node)
      
      # Try to get from cache
      cached_path = Rails.cache.read(cache_key)
      return cached_path if cached_path
      
      # Calculate path
      path = calculate_path(node)
      
      # Store in cache
      Rails.cache.write(cache_key, path, expires_in: CACHE_TTL)
      
      path
    end
    
    def clear_for_node(node)
      return unless node
      
      # Clear this node's cache
      Rails.cache.delete(build_key(node))
      
      # Clear cache for all descendants
      if node.respond_to?(:descendants)
        node.descendants.each do |descendant|
          Rails.cache.delete(build_key(descendant))
        end
      end
    end
    
    def clear_all
      Rails.cache.delete_matched("#{CACHE_PREFIX}:*")
    end
    
    private
    
    def build_key(node)
      "#{CACHE_PREFIX}:#{node.class.name}:#{node.id}"
    end
    
    def calculate_path(node)
      path = []
      current = node
      
      while current.parent_id.present?
        current = current.class.find_by(id: current.parent_id)
        break unless current
        path.unshift(current)
      end
      
      path
    end
  end
end