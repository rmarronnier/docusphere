module Immo
  module Promo
    class ProgressCacheService
      CACHE_TTL = 10.minutes
      CACHE_PREFIX = 'immo_promo_progress'
      
      class << self
        def project_progress(project)
          return 0 unless project
          
          cache_key = "#{CACHE_PREFIX}:project:#{project.id}:overall"
          
          # Try to get from cache
          cached_value = Rails.cache.read(cache_key)
          return cached_value if cached_value
          
          # Calculate progress
          progress = project.calculate_overall_progress
          
          # Store in cache
          Rails.cache.write(cache_key, progress, expires_in: CACHE_TTL)
          
          progress
        end
        
        def phase_progress(phase)
          return 0 unless phase
          
          cache_key = "#{CACHE_PREFIX}:phase:#{phase.id}:completion"
          
          # Try to get from cache
          cached_value = Rails.cache.read(cache_key)
          return cached_value if cached_value
          
          # Calculate progress
          progress = phase.completion_percentage
          
          # Store in cache
          Rails.cache.write(cache_key, progress, expires_in: CACHE_TTL)
          
          progress
        end
        
        def clear_project_cache(project)
          return unless project
          
          # Clear project cache
          Rails.cache.delete("#{CACHE_PREFIX}:project:#{project.id}:overall")
          
          # Clear phase caches
          project.phases.each do |phase|
            clear_phase_cache(phase)
          end
        end
        
        def clear_phase_cache(phase)
          return unless phase
          
          Rails.cache.delete("#{CACHE_PREFIX}:phase:#{phase.id}:completion")
          
          # Also clear parent project cache
          clear_project_cache(phase.project) if phase.project
        end
        
        def clear_all
          Rails.cache.delete_matched("#{CACHE_PREFIX}:*")
        end
      end
    end
  end
end