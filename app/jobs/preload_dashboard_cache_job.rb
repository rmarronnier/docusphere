# frozen_string_literal: true

class PreloadDashboardCacheJob < ApplicationJob
  queue_as :default
  
  # Retry configuration for reliability
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(user_id, widget_types = [])
    user = User.find_by(id: user_id)
    return unless user&.organization

    cache_service = DashboardCacheService.new(user)
    
    # Preload each widget type in parallel if possible
    widget_types.each do |widget_type|
      begin
        Rails.logger.info "Preloading cache for user #{user_id}, widget: #{widget_type}"
        
        # Force refresh to ensure fresh data
        cache_service.cached_widget_data(widget_type.to_sym, force_refresh: true)
        
        Rails.logger.info "Successfully preloaded cache for widget: #{widget_type}"
      rescue => e
        Rails.logger.error "Failed to preload cache for widget #{widget_type}: #{e.message}"
        # Continue with other widgets even if one fails
      end
    end
    
    Rails.logger.info "Completed dashboard cache preload for user #{user_id}"
  end
end