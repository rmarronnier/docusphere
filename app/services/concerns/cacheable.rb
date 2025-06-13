# Concern for services that use caching
module Cacheable
  extend ActiveSupport::Concern

  included do
    class_attribute :cache_config
    self.cache_config = {
      default_expires_in: 1.hour,
      namespace: nil,
      compress: true
    }
  end

  class_methods do
    # Configure caching for the service
    def configure_cache(options = {})
      self.cache_config = cache_config.merge(options)
    end

    # Set default cache expiration
    def cache_expires_in(duration)
      configure_cache(default_expires_in: duration)
    end

    # Set cache namespace
    def cache_namespace(namespace)
      configure_cache(namespace: namespace)
    end
  end

  # Get data from cache or execute block
  def cached(key, expires_in: nil, &block)
    cache_key = build_cache_key(key)
    expires_in ||= cache_config[:default_expires_in]
    
    Rails.cache.fetch(cache_key, expires_in: expires_in, compress: cache_config[:compress]) do
      yield
    end
  end

  # Cache with automatic invalidation based on dependencies
  def cached_with_dependencies(key, dependencies: [], expires_in: nil, &block)
    dependency_key = build_dependency_key(dependencies)
    full_key = "#{key}:#{dependency_key}"
    
    cached(full_key, expires_in: expires_in, &block)
  end

  # Invalidate cache by key
  def invalidate_cache(key)
    cache_key = build_cache_key(key)
    Rails.cache.delete(cache_key)
  end

  # Invalidate all cache for this service
  def invalidate_all_cache
    pattern = build_cache_key('*')
    Rails.cache.delete_matched(pattern)
  end

  # Get cache statistics
  def cache_stats(key = nil)
    if key
      cache_key = build_cache_key(key)
      {
        exists: Rails.cache.exist?(cache_key),
        key: cache_key
      }
    else
      # Global stats would require Redis-specific implementation
      { namespace: cache_namespace }
    end
  end

  # Warm up cache with precomputed values
  def warm_cache(data_map, expires_in: nil)
    expires_in ||= cache_config[:default_expires_in]
    
    data_map.each do |key, value|
      cache_key = build_cache_key(key)
      Rails.cache.write(cache_key, value, expires_in: expires_in, compress: cache_config[:compress])
    end
  end

  # Cache multiple keys in batch
  def batch_cache(keys, expires_in: nil, &block)
    expires_in ||= cache_config[:default_expires_in]
    results = {}
    
    # Check which keys are already cached
    cache_keys = keys.map { |key| [key, build_cache_key(key)] }.to_h
    cached_values = Rails.cache.read_multi(*cache_keys.values)
    
    # Separate cached from uncached
    uncached_keys = []
    
    keys.each do |key|
      cache_key = cache_keys[key]
      if cached_values.key?(cache_key)
        results[key] = cached_values[cache_key]
      else
        uncached_keys << key
      end
    end
    
    # Fetch uncached values
    unless uncached_keys.empty?
      uncached_values = yield(uncached_keys)
      
      # Cache the new values
      write_data = {}
      uncached_keys.each do |key|
        value = uncached_values[key]
        results[key] = value
        write_data[cache_keys[key]] = value
      end
      
      Rails.cache.write_multi(write_data, expires_in: expires_in, compress: cache_config[:compress])
    end
    
    results
  end

  # Cache with automatic refresh in background
  def cached_with_refresh(key, refresh_threshold: 0.8, expires_in: nil, &block)
    expires_in ||= cache_config[:default_expires_in]
    cache_key = build_cache_key(key)
    
    # Check if key exists and its age
    if Rails.cache.exist?(cache_key)
      value = Rails.cache.read(cache_key)
      
      # If we have cache info, check if refresh is needed
      info_key = "#{cache_key}:info"
      if Rails.cache.exist?(info_key)
        cache_info = Rails.cache.read(info_key)
        age_ratio = (Time.current - cache_info[:created_at]) / expires_in.to_f
        
        if age_ratio > refresh_threshold
          # Refresh in background
          refresh_cache_async(key, expires_in, &block)
        end
      end
      
      return value
    end
    
    # Cache miss - compute and store
    value = yield
    Rails.cache.write(cache_key, value, expires_in: expires_in, compress: cache_config[:compress])
    Rails.cache.write("#{cache_key}:info", { created_at: Time.current }, expires_in: expires_in)
    
    value
  end

  private

  def build_cache_key(key)
    parts = []
    parts << cache_namespace if cache_namespace
    parts << self.class.name.underscore
    parts << key.to_s
    parts.join(':')
  end

  def build_dependency_key(dependencies)
    return 'static' if dependencies.empty?
    
    dependency_values = dependencies.map do |dep|
      case dep
      when ActiveRecord::Base
        "#{dep.class.name}:#{dep.id}:#{dep.updated_at.to_i}"
      when Class
        "#{dep.name}:#{dep.maximum(:updated_at)&.to_i || 0}"
      when Symbol, String
        dep.to_s
      else
        dep.hash.to_s
      end
    end
    
    Digest::MD5.hexdigest(dependency_values.join(':'))
  end

  def cache_namespace
    cache_config[:namespace] || self.class.name.underscore
  end

  def refresh_cache_async(key, expires_in, &block)
    # In a real application, you'd use a background job
    # For now, we'll just update immediately
    Thread.new do
      begin
        value = yield
        cache_key = build_cache_key(key)
        Rails.cache.write(cache_key, value, expires_in: expires_in, compress: cache_config[:compress])
        Rails.cache.write("#{cache_key}:info", { created_at: Time.current }, expires_in: expires_in)
      rescue => e
        Rails.logger.error "Cache refresh failed for #{key}: #{e.message}"
      end
    end
  end
end