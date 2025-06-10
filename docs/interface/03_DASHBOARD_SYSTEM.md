# 📊 Système de Tableaux de Bord

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture des Données](#architecture-des-données)
3. [Personnalisation](#personnalisation)
4. [Performance et Cache](#performance-et-cache)
5. [API et Intégrations](#api-et-intégrations)

## 🎯 Vue d'ensemble

Le système de tableaux de bord de Docusphere offre une expérience personnalisée selon le profil utilisateur, avec des widgets modulaires, drag & drop, et mise en cache intelligente.

### Fonctionnalités Clés

- **Dashboards personnalisés** par profil utilisateur
- **Widgets modulaires** redimensionnables et repositionnables
- **Mise en cache Redis** pour performances optimales
- **Actualisation en temps réel** pour données critiques
- **Interface responsive** mobile-first

## 🗄️ Architecture des Données

### Modèle UserProfile

```ruby
# app/models/user_profile.rb
class UserProfile < ApplicationRecord
  belongs_to :user
  has_many :dashboard_widgets, -> { order(:position) }, dependent: :destroy
  
  # Enum pour les types de profils
  enum profile_type: {
    direction: 'direction',
    chef_projet: 'chef_projet', 
    juriste: 'juriste',
    architecte: 'architecte',
    commercial: 'commercial',
    controleur: 'controleur',
    expert_technique: 'expert_technique',
    assistant_rh: 'assistant_rh',
    communication: 'communication',
    admin_system: 'admin_system'
  }
  
  # Validations
  validates :profile_type, presence: true
  validates :user_id, uniqueness: { scope: :active }, if: :active?
  
  # Store accessors pour les préférences
  store_accessor :preferences, :theme, :language, :timezone, :date_format
  store_accessor :dashboard_config, :layout, :refresh_interval, :collapsed_sections
  store_accessor :notification_settings, :email_alerts, :push_notifications, :alert_types
  
  # Callbacks
  after_create :setup_default_widgets
  
  def setup_default_widgets
    widget_configs = DefaultWidgetService.new(self).generate_widgets
    widget_configs.each_with_index do |config, index|
      dashboard_widgets.create!(
        widget_type: config[:type],
        position: index,
        width: config[:width] || 1,
        height: config[:height] || 1,
        config: config[:config] || {}
      )
    end
  end
end
```

### Modèle DashboardWidget

```ruby
# app/models/dashboard_widget.rb
class DashboardWidget < ApplicationRecord
  belongs_to :user_profile
  
  # Validations
  validates :widget_type, presence: true
  validates :position, presence: true, uniqueness: { scope: :user_profile_id }
  validates :width, :height, presence: true, 
            inclusion: { in: 1..4, message: "doit être entre 1 et 4" }
  
  # Scopes
  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order(:position) }
  
  # Callbacks
  before_validation :set_default_dimensions
  after_update :clear_cache
  after_destroy :clear_cache
  
  private
  
  def set_default_dimensions
    self.width ||= 1
    self.height ||= 1
  end
  
  def clear_cache
    WidgetCacheService.clear_widget_cache(self)
    WidgetCacheService.clear_profile_cache(user_profile)
  end
end
```

### Migration

```ruby
# db/migrate/20250610_create_user_profiles_and_dashboard_widgets.rb
class CreateUserProfilesAndDashboardWidgets < ActiveRecord::Migration[7.1]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :profile_type, null: false
      t.jsonb :preferences, default: {}
      t.jsonb :dashboard_config, default: {}
      t.jsonb :notification_settings, default: {}
      t.boolean :active, default: true
      
      t.timestamps
    end
    
    add_index :user_profiles, :profile_type
    add_index :user_profiles, [:user_id, :active], unique: true, where: "active = true"
    
    create_table :dashboard_widgets do |t|
      t.references :user_profile, null: false, foreign_key: true
      t.string :widget_type, null: false
      t.integer :position, null: false
      t.integer :width, default: 1
      t.integer :height, default: 1
      t.jsonb :config, default: {}
      t.boolean :visible, default: true
      
      t.timestamps
    end
    
    add_index :dashboard_widgets, [:user_profile_id, :position]
  end
end
```

## 🎨 Personnalisation

### Service de Personnalisation

```ruby
# app/services/dashboard_personalization_service.rb
class DashboardPersonalizationService
  attr_reader :user, :profile
  
  def initialize(user)
    @user = user
    @profile = user.active_profile
  end
  
  def personalized_dashboard
    {
      widgets: active_widgets,
      actions: priority_actions,
      navigation: navigation_items,
      notifications: recent_notifications,
      metrics: key_metrics
    }
  end
  
  def active_widgets
    return [] unless profile
    
    # Preload all widgets data in cache
    WidgetCacheService.preload_dashboard(profile)
    
    profile.dashboard_widgets.visible.includes(:user_profile).map do |widget|
      {
        id: widget.id,
        type: widget.widget_type,
        position: widget.position,
        width: widget.width,
        height: widget.height,
        config: widget.config,
        data: WidgetCacheService.get_widget_data(widget, user)
      }
    end
  end
  
  def priority_actions
    case profile&.profile_type
    when 'direction'
      direction_priority_actions
    when 'chef_projet'
      chef_projet_priority_actions
    when 'juriste'
      juriste_priority_actions
    else
      default_priority_actions
    end
  end
  
  private
  
  def direction_priority_actions
    actions = []
    
    # Documents en attente de validation
    pending_validations = DocumentValidation.where(validator: user, status: 'pending').count
    if pending_validations > 0
      actions << {
        type: 'validation',
        title: 'Validations en attente',
        count: pending_validations,
        urgency: 'high',
        link: '/validations/pending',
        icon: 'check-circle'
      }
    end
    
    actions
  end
end
```

### Service de Widgets par Défaut

```ruby
# app/services/default_widget_service.rb
class DefaultWidgetService
  attr_reader :user_profile
  
  def initialize(user_profile)
    @user_profile = user_profile
  end
  
  def generate_widgets
    case user_profile.profile_type
    when 'direction'
      direction_widgets
    when 'chef_projet'
      chef_projet_widgets
    when 'juriste'
      juriste_widgets
    when 'commercial'
      commercial_widgets
    else
      default_widgets
    end
  end
  
  private
  
  def direction_widgets
    [
      {
        type: 'portfolio_overview',
        width: 2,
        height: 2,
        config: {
          title: 'Vue Portfolio',
          show_financial_summary: true,
          show_risk_indicators: true
        }
      },
      {
        type: 'financial_summary',
        width: 1,
        height: 1,
        config: {
          title: 'Résumé Financier',
          show_variance: true,
          comparison_period: 'month'
        }
      },
      {
        type: 'risk_matrix',
        width: 1,
        height: 1,
        config: {
          title: 'Matrice des Risques',
          risk_threshold: 'medium'
        }
      },
      {
        type: 'pending_approvals',
        width: 2,
        height: 1,
        config: {
          title: 'Approbations en Attente',
          approval_threshold: 50000
        }
      }
    ]
  end
  
  def chef_projet_widgets
    [
      {
        type: 'project_timeline',
        width: 2,
        height: 2,
        config: {
          title: 'Planning Projet',
          show_dependencies: true,
          show_critical_path: true
        }
      },
      {
        type: 'task_kanban',
        width: 2,
        height: 2,
        config: {
          title: 'Tâches',
          columns: ['todo', 'in_progress', 'review', 'done'],
          show_assignee: true
        }
      },
      {
        type: 'resource_dashboard',
        width: 2,
        height: 1,
        config: {
          title: 'Ressources',
          show_utilization: true,
          show_availability: true
        }
      },
      {
        type: 'team_communication',
        width: 1,
        height: 2,
        config: {
          title: 'Équipe',
          show_recent_messages: true
        }
      },
      {
        type: 'document_validation',
        width: 1,
        height: 1,
        config: {
          title: 'Validations',
          show_pending_only: true
        }
      }
    ]
  end
end
```

## ⚡ Performance et Cache

### Service de Cache Redis

```ruby
# app/services/widget_cache_service.rb
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
    
    private
    
    def cache_ttl_for_widget(widget)
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
      case widget.widget_type
      when 'recent_documents'
        calculate_recent_documents(user, widget.config)
      when 'pending_tasks'
        calculate_pending_tasks(user, widget.config)
      when 'notifications'
        calculate_notifications(user, widget.config)
      when 'statistics'
        calculate_statistics(user, widget.config)
      else
        { content: "Widget type '#{widget.widget_type}' not implemented" }
      end
    end
  end
end
```

### Configuration Redis

```yaml
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  pool_size: 5,
  pool_timeout: 5,
  reconnect_attempts: 1,
  namespace: 'docusphere',
  compress: true,
  compression_threshold: 1.kilobyte
}

# config/environments/development.rb
config.cache_store = :redis_cache_store, {
  url: 'redis://localhost:6379/1',
  namespace: 'docusphere_dev'
}
```

## 🔄 API et Intégrations

### Controller Dashboard

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_profile
  before_action :load_widget, only: [:update_widget, :refresh_widget]
  
  def show
    service = DashboardPersonalizationService.new(current_user)
    @dashboard_data = service.personalized_dashboard
  end
  
  def update_widget
    if @widget.update(widget_params)
      render json: { status: 'success', widget: widget_data(@widget) }
    else
      render json: { status: 'error', errors: @widget.errors.full_messages }, 
             status: :unprocessable_entity
    end
  end
  
  def reorder_widgets
    widget_ids = params[:widget_ids] || []
    user_widget_ids = current_user.active_profile.dashboard_widgets.pluck(:id)
    
    # Only reorder widgets that belong to the current user
    valid_widget_ids = widget_ids.select { |id| user_widget_ids.include?(id.to_i) }
    
    valid_widget_ids.each_with_index do |widget_id, index|
      current_user.active_profile.dashboard_widgets.find(widget_id).update(position: index + 1)
    end
    
    render json: { status: 'success' }
  end
  
  def refresh_widget
    # Update last refreshed timestamp
    @widget.config['last_refreshed_at'] = Time.current.iso8601
    @widget.save
    
    # Get fresh widget data
    widget_data = WidgetCacheService.get_widget_data(@widget, current_user, force_refresh: true)
    
    render json: { status: 'success', widget: widget_data }
  end
  
  private
  
  def widget_params
    params.require(:widget).permit(:position, :width, :height, config: {})
  end
  
  def widget_data(widget)
    {
      id: widget.id,
      widget_type: widget.widget_type,
      position: widget.position,
      width: widget.width,
      height: widget.height,
      config: widget.config
    }
  end
end
```

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :dashboard, only: [:show] do
    collection do
      post 'widgets/reorder', to: 'dashboard#reorder_widgets'
    end
    
    member do
      post 'widgets/:id/update', to: 'dashboard#update_widget', as: 'update_widget'
      post 'widgets/:id/refresh', to: 'dashboard#refresh_widget', as: 'refresh_widget'
    end
  end
end
```

### JavaScript Controllers

```javascript
// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["widgets"]
  
  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
  }
  
  async reorderWidgets(event) {
    const { widgetIds } = event.detail
    
    try {
      const response = await fetch('/dashboard/widgets/reorder', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ widget_ids: widgetIds })
      })
      
      if (!response.ok) {
        console.error(`Server error: ${response.status}`)
        return
      }
      
      this.dispatch("widgets-reordered", { detail: { widgetIds } })
    } catch (error) {
      console.error('Error reordering widgets:', error)
    }
  }
  
  async resizeWidget(event) {
    const { widgetId, width, height } = event.detail
    
    try {
      const response = await fetch(`/dashboard/widgets/${widgetId}/update`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ 
          widget: { width, height } 
        })
      })
      
      if (!response.ok) {
        console.error(`Server error: ${response.status}`)
        return
      }
      
      this.dispatch("widget-resized", { detail: { widgetId, width, height } })
    } catch (error) {
      console.error('Error resizing widget:', error)
    }
  }
}
```

### Métriques et Monitoring

```ruby
# app/services/metrics_service.rb
class MetricsService
  attr_reader :user
  
  def initialize(user)
    @user = user
  end
  
  def key_metrics
    Rails.cache.fetch("metrics:user:#{user.id}", expires_in: 5.minutes) do
      [
        documents_metric,
        validations_metric,
        projects_metric,
        performance_metric
      ].compact
    end
  end
  
  private
  
  def documents_metric
    count = Document.accessible_by(user).count
    trend = calculate_trend(:documents, count)
    
    {
      label: 'Documents',
      value: count,
      trend: trend,
      icon: 'document',
      color: 'blue',
      change: trend[:percentage]
    }
  end
  
  def validations_metric
    count = ValidationRequest.pending.for_user(user).count
    return nil if count == 0
    
    {
      label: 'Validations en attente',
      value: count,
      trend: { direction: 'neutral', percentage: 0 },
      icon: 'check-circle',
      color: 'orange',
      urgency: count > 5 ? 'high' : 'medium'
    }
  end
end
```

---

**Navigation :** [← Architecture](./02_ARCHITECTURE.md) | [Widget Library →](./04_WIDGET_LIBRARY.md)