class WidgetCacheService
  CACHE_TTL = 10.minutes
  SHORT_CACHE_TTL = 1.minute
  CACHE_PREFIX = 'widgets'
  
  class << self
    def get_widget_data(widget, user, force_refresh: false)
      return calculate_widget_data(widget, user) if force_refresh
      
      cache_key = build_widget_key(widget, user)
      
      # Try to get from cache
      cached_data = Rails.cache.read(cache_key)
      return cached_data if cached_data.present?
      
      # Calculate widget data
      data = calculate_widget_data(widget, user)
      
      # Determine cache TTL based on widget type
      ttl = cache_ttl_for_widget(widget)
      
      # Store in cache
      Rails.cache.write(cache_key, data, expires_in: ttl)
      
      data
    end
    
    def get_dashboard_widgets(user_profile, force_refresh: false)
      return calculate_dashboard_widgets(user_profile) if force_refresh
      
      cache_key = build_dashboard_key(user_profile)
      
      # Try to get from cache
      cached_data = Rails.cache.read(cache_key)
      return cached_data if cached_data.present?
      
      # Calculate dashboard data
      data = calculate_dashboard_widgets(user_profile)
      
      # Store in cache
      Rails.cache.write(cache_key, data, expires_in: SHORT_CACHE_TTL)
      
      data
    end
    
    def clear_widget_cache(widget)
      return unless widget
      
      if Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
        redis = Rails.cache.redis
        pattern = "#{CACHE_PREFIX}:widget:#{widget.id}:*"
        
        cursor = 0
        loop do
          cursor, keys = redis.scan(cursor, match: pattern, count: 100)
          redis.del(*keys) unless keys.empty?
          break if cursor == "0"
        end
      else
        Rails.cache.delete_matched("#{CACHE_PREFIX}:widget:#{widget.id}:*")
      end
    end
    
    def clear_user_cache(user)
      return unless user
      
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
    
    def clear_profile_cache(user_profile)
      return unless user_profile
      
      if Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
        redis = Rails.cache.redis
        pattern = "#{CACHE_PREFIX}:profile:#{user_profile.id}:*"
        
        cursor = 0
        loop do
          cursor, keys = redis.scan(cursor, match: pattern, count: 100)
          redis.del(*keys) unless keys.empty?
          break if cursor == "0"
        end
      else
        Rails.cache.delete_matched("#{CACHE_PREFIX}:profile:#{user_profile.id}:*")
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
    
    # Preload widgets for a dashboard
    def preload_dashboard(user_profile)
      return unless user_profile
      
      # Preload all widgets in parallel using Rails cache multi-read
      widget_keys = user_profile.dashboard_widgets.visible.map do |widget|
        build_widget_key(widget, user_profile.user)
      end
      
      # Multi-read from cache
      cached_data = Rails.cache.read_multi(*widget_keys)
      
      # Calculate missing data
      user_profile.dashboard_widgets.visible.each do |widget|
        key = build_widget_key(widget, user_profile.user)
        next if cached_data[key].present?
        
        # Calculate and cache missing data
        get_widget_data(widget, user_profile.user)
      end
    end
    
    private
    
    def build_widget_key(widget, user)
      "#{CACHE_PREFIX}:widget:#{widget.id}:user:#{user.id}:data"
    end
    
    def build_dashboard_key(user_profile)
      "#{CACHE_PREFIX}:profile:#{user_profile.id}:dashboard"
    end
    
    def cache_ttl_for_widget(widget)
      # Different TTLs based on widget type
      case widget.widget_type
      when 'recent_documents', 'recent_activity', 'notifications'
        SHORT_CACHE_TTL # 1 minute for frequently changing data
      when 'statistics', 'metrics', 'portfolio_overview'
        CACHE_TTL # 10 minutes for slower changing data
      else
        5.minutes # Default 5 minutes
      end
    end
    
    def calculate_widget_data(widget, user)
      # Delegate to appropriate service based on widget type
      case widget.widget_type
      when 'recent_documents'
        calculate_recent_documents(user, widget.config)
      when 'pending_tasks'
        calculate_pending_tasks(user, widget.config)
      when 'notifications'
        calculate_notifications(user, widget.config)
      when 'quick_access'
        calculate_quick_access(user, widget.config)
      when 'statistics'
        calculate_statistics(user, widget.config)
      else
        { content: "Widget type '#{widget.widget_type}' not implemented" }
      end
    end
    
    def calculate_dashboard_widgets(user_profile)
      user_profile.dashboard_widgets.visible.includes(:user_profile).map do |widget|
        {
          id: widget.id,
          type: widget.widget_type,
          position: widget.position,
          width: widget.width,
          height: widget.height,
          config: widget.config,
          data: get_widget_data(widget, user_profile.user)
        }
      end
    end
    
    # Widget-specific calculations
    def calculate_recent_documents(user, config)
      limit = config['limit'] || 5
      
      # Use the existing scope for documents readable by user
      documents = Document.readable_by(user)
                         .order(updated_at: :desc)
                         .limit(limit)
                         .includes(:tags, :uploaded_by)
      
      {
        content: documents.map do |doc|
          {
            id: doc.id,
            name: doc.title,
            updated_at: doc.updated_at,
            user: doc.uploaded_by.display_name,
            tags: doc.tags.pluck(:name)
          }
        end,
        count: documents.count,
        total: Document.readable_by(user).count
      }
    end
    
    def calculate_pending_tasks(user, config)
      limit = config['limit'] || 10
      
      # For now, return mock data
      # In a real implementation, this would query actual tasks
      {
        content: [
          { id: 1, title: "Valider document budget", urgency: "high", due_date: 2.days.from_now },
          { id: 2, title: "Réviser contrat fournisseur", urgency: "medium", due_date: 1.week.from_now }
        ],
        count: 2,
        total: 5
      }
    end
    
    def calculate_notifications(user, config)
      limit = config['limit'] || 5
      
      notifications = user.notifications
                         .unread
                         .order(created_at: :desc)
                         .limit(limit)
      
      {
        content: notifications.map do |notif|
          {
            id: notif.id,
            title: notif.title,
            message: notif.message,
            created_at: notif.created_at,
            notification_type: notif.notification_type
          }
        end,
        count: notifications.count,
        total: user.notifications.unread.count
      }
    end
    
    def calculate_quick_access(user, config)
      # Quick access items based on user profile
      items = []
      
      if user.active_profile.can_access_module?('immo_promo')
        items << { name: "Projets", path: "/immo/promo/projects", icon: "folder" }
      end
      
      items += [
        { name: "Documents", path: "/ged", icon: "document" },
        { name: "Recherche", path: "/search", icon: "search" }
      ]
      
      { content: items }
    end
    
    def calculate_statistics(user, config)
      # Calculate various statistics
      {
        content: {
          documents_count: Document.readable_by(user).count,
          pending_validations: ValidationRequest.where(status: 'pending').joins(:document_validations).where(document_validations: { validator_id: user.id }).count,
          active_projects: user.active_profile&.profile_type == 'chef_projet' ? 5 : 0,
          team_members: user.organization.users.count
        }
      }
    end
  end
end