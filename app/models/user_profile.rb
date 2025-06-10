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
  
  # Scopes
  scope :active, -> { where(active: true) }
  
  # Callbacks
  after_create :setup_default_widgets
  
  # Store accessors pour les préférences
  store_accessor :preferences, :theme, :language, :timezone, :date_format
  store_accessor :dashboard_config, :layout, :refresh_interval, :collapsed_sections
  store_accessor :notification_settings, :email_alerts, :push_notifications, :alert_types
  
  # Méthodes d'instance
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
  
  def available_widgets
    # Pour l'instant, retourner une liste basique
    # WidgetRegistry sera implémenté plus tard
    [
      { type: 'welcome', name: 'Message de bienvenue' },
      { type: 'recent_activity', name: 'Activité récente' },
      { type: 'notifications', name: 'Notifications' }
    ]
  end
  
  def can_access_module?(module_name)
    # Pour l'instant, autoriser l'accès basé sur le type de profil
    # ProfilePermissionService sera implémenté plus tard
    case module_name
    when 'immo_promo'
      %w[direction chef_projet commercial controleur].include?(profile_type)
    when 'legal'
      %w[direction juriste].include?(profile_type)
    else
      true
    end
  end
  
  def navigation_items
    # Pour l'instant, retourner des items de base
    # NavigationService sera implémenté plus tard
    [
      { name: 'Tableau de bord', path: '/dashboard', icon: 'home' },
      { name: 'Documents', path: '/ged', icon: 'folder' },
      { name: 'Notifications', path: '/notifications', icon: 'bell' }
    ]
  end
  
  def priority_actions
    # Pour l'instant, retourner un tableau vide
    # ActionService sera implémenté plus tard
    []
  end
end