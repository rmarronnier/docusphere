# 📐 Plan de Refonte de l'Interface Docusphere

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Analyse des Profils Utilisateurs](#analyse-des-profils-utilisateurs)
3. [Architecture de la Nouvelle Interface](#architecture-de-la-nouvelle-interface)
4. [Phase 1 : Infrastructure et Fondations](#phase-1--infrastructure-et-fondations)
5. [Phase 2 : Dashboards Personnalisés par Profil](#phase-2--dashboards-personnalisés-par-profil)
6. [Phase 3 : Optimisations et Personnalisation](#phase-3--optimisations-et-personnalisation)
7. [Phase 4 : Intégration Mobile](#phase-4--intégration-mobile)
8. [Métriques et KPIs](#métriques-et-kpis)
9. [Annexes Techniques](#annexes-techniques)

## 🎯 Vue d'ensemble

### Objectifs de la Refonte

La refonte de l'interface Docusphere vise à transformer une plateforme de GED généraliste en un **outil intelligent et adaptatif** qui s'ajuste automatiquement aux besoins spécifiques de chaque utilisateur selon son profil, ses responsabilités et son contexte de travail.

### Principes Directeurs

1. **Personnalisation contextuelle** : L'interface s'adapte au profil et aux tâches de l'utilisateur
2. **Efficacité maximale** : Réduction du nombre de clics pour les actions courantes
3. **Information pertinente** : Affichage prioritaire des données critiques pour chaque profil
4. **Fluidité de navigation** : Transitions naturelles entre les différentes sections
5. **Cohérence visuelle** : Design system unifié mais flexible

### Impact Attendu

- **-50%** de temps de navigation pour les tâches courantes
- **+80%** de satisfaction utilisateur
- **<1s** temps de chargement du dashboard
- **100%** d'adoption des nouvelles fonctionnalités sous 3 mois

## 👥 Analyse des Profils Utilisateurs

### Matrice des Profils et Permissions

| Profil | Rôle Système | Modules Principaux | Actions Prioritaires | Besoins Spécifiques |
|--------|--------------|-------------------|---------------------|---------------------|
| **Direction Générale** | `super_admin` | Tous modules | Validations stratégiques, Monitoring global | Vue consolidée, KPIs temps réel, Alertes critiques |
| **Chef de Projet** | `admin` + Immo::Promo | GED, Immo::Promo | Coordination, Planning, Assignations | Timeline projet, Kanban tâches, Ressources |
| **Juriste Immobilier** | `manager` | GED, Permis, Contrats | Validations juridiques, Veille | Conformité, Échéancier légal, Archives |
| **Architecte** | `manager` externe | GED technique, Plans | Upload plans, Validations techniques | Versionning plans, Échanges BET, Modifications |
| **Commercial** | `manager` | Commercial, CRM | Réservations, Contrats vente | Pipeline, Stock temps réel, Objectifs |
| **Contrôleur Gestion** | `manager` | Financier, Reporting | Validation factures, Analyse | Budgets, Variances, Tableaux de bord |
| **Expert Technique** | `user` externe | GED technique limitée | Upload études, Consultations | Documents mission, Échanges architecte |
| **Assistant RH** | `user` | RH, Certifications | MAJ certifications, Contrats | Alertes renouvellement, Suivi intervenants |
| **Communication** | `user` | Marketing, Médias | Upload visuels, Validations | Médiathèque, Partage externe, Branding |
| **Admin Système** | `admin` | Administration | Gestion utilisateurs, Config | Monitoring, Logs, Permissions, Maintenance |

### Personas Détaillés

#### 👔 Marie Dupont - Directrice Générale
- **Âge** : 52 ans
- **Expérience** : 25 ans dans l'immobilier
- **Objectifs** : Surveiller la santé globale des projets, anticiper les risques, valider les décisions stratégiques
- **Frustrations actuelles** : Trop de clics pour accéder aux KPIs, pas de vue consolidée, alertes noyées dans les notifications
- **Besoins critiques** : 
  - Dashboard exécutif avec drill-down
  - Alertes intelligentes (seuils configurables)
  - Accès rapide aux documents de validation
  - Vue portfolio multi-projets

#### 🏗️ Thomas Martin - Chef de Projet
- **Âge** : 38 ans
- **Expérience** : 12 ans en gestion de projet
- **Objectifs** : Livrer les projets dans les délais et budgets, coordonner efficacement les équipes
- **Frustrations actuelles** : Navigation complexe entre modules, pas de vue unifiée projet, difficultés de suivi temps réel
- **Besoins critiques** :
  - Timeline interactive avec dépendances
  - Vue Kanban des tâches par phase
  - Tableau de bord ressources
  - Communication intégrée équipes

## 🏗️ Architecture de la Nouvelle Interface

### Structure Globale

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NAVBAR ADAPTATIVE                           │
│  Logo | Navigation contextuelle | Recherche | Notifs | Profil      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────────────────────────────┐  │
│  │                 │  │                                         │  │
│  │  ACTIONS PANEL  │  │          ZONE PRINCIPALE              │  │
│  │                 │  │                                         │  │
│  │ ┌─────────────┐ │  │    ┌─────────────┐ ┌─────────────┐    │  │
│  │ │ Validations │ │  │    │   Widget 1   │ │   Widget 2   │    │  │
│  │ │ en attente  │ │  │    └─────────────┘ └─────────────┘    │  │
│  │ └─────────────┘ │  │                                         │  │
│  │                 │  │    ┌─────────────┐ ┌─────────────┐    │  │
│  │ ┌─────────────┐ │  │    │   Widget 3   │ │   Widget 4   │    │  │
│  │ │   Tâches    │ │  │    └─────────────┘ └─────────────┘    │  │
│  │ │ priorités   │ │  │                                         │  │
│  │ └─────────────┘ │  │    ┌─────────────────────────────┐    │  │
│  │                 │  │    │      Widget Principal       │    │  │
│  │ ┌─────────────┐ │  │    └─────────────────────────────┘    │  │
│  │ │   Alertes   │ │  │                                         │  │
│  │ └─────────────┘ │  └─────────────────────────────────────────┘  │
│  │                 │                                               │
│  │ ┌─────────────┐ │  ┌─────────────────────────────────────────┐  │
│  │ │   Favoris   │ │  │         ZONE SECONDAIRE (Optionnelle)   │  │
│  │ └─────────────┘ │  └─────────────────────────────────────────┘  │
│  └─────────────────┘                                               │
└─────────────────────────────────────────────────────────────────────┘
```

### Composants Clés

1. **Navbar Adaptative**
   - Logo et nom de l'organisation
   - Navigation principale contextuelle selon profil
   - Barre de recherche intelligente avec suggestions
   - Centre de notifications avec filtres
   - Menu utilisateur avec accès rapide

2. **Actions Panel (Sidebar)**
   - Actions prioritaires triées par urgence
   - Compteurs visuels (badges)
   - Accès rapide aux favoris
   - Zone personnalisable

3. **Zone Principale**
   - Grille de widgets adaptative
   - Disposition flexible (1-4 colonnes)
   - Widgets redimensionnables
   - Drag & drop pour réorganisation

4. **Widgets Modulaires**
   - Header avec titre et actions
   - Corps avec contenu spécifique
   - Footer optionnel avec liens
   - États : normal, loading, error, empty

## 📦 Phase 1 : Infrastructure et Fondations

### 1.1 Modélisation des Profils Utilisateurs

#### Migration Base de Données

```ruby
# db/migrate/20250610_create_user_profiles.rb
class CreateUserProfiles < ActiveRecord::Migration[7.1]
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
    
    # Table pour les préférences de widgets
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

#### Modèle UserProfile

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
    WidgetRegistry.widgets_for_profile(profile_type)
  end
  
  def can_access_module?(module_name)
    ProfilePermissionService.new(self).can_access?(module_name)
  end
  
  def navigation_items
    NavigationService.new(self).items
  end
  
  def priority_actions
    ActionService.new(user).priority_actions_for_profile(profile_type)
  end
end
```

### 1.2 Services de Personnalisation

#### Service Principal de Dashboard

```ruby
# app/services/dashboard_personalization_service.rb
class DashboardPersonalizationService
  attr_reader :user, :profile
  
  def initialize(user)
    @user = user
    @profile = user.active_profile
  end
  
  def dashboard_data
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
    
    profile.dashboard_widgets.visible.includes(:widget_type).map do |widget|
      {
        id: widget.id,
        type: widget.widget_type,
        position: widget.position,
        size: { width: widget.width, height: widget.height },
        config: widget.config,
        data: load_widget_data(widget)
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
  
  def load_widget_data(widget)
    widget_class = "Widgets::#{widget.widget_type.camelize}Widget".constantize
    widget_instance = widget_class.new(user, widget.config)
    widget_instance.data
  rescue NameError => e
    Rails.logger.error "Widget class not found: #{widget.widget_type}"
    { error: "Widget non disponible" }
  end
  
  def direction_priority_actions
    actions = []
    
    # Documents en attente de validation
    pending_validations = ValidationRequest.joins(:validatable)
                                          .where(status: 'pending')
                                          .where(reviewer: user)
                                          .count
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
    
    # Budgets à approuver
    pending_budgets = Immo::Promo::Budget.where(status: 'pending_approval')
                                         .joins(:project)
                                         .where(projects: { organization: user.organization })
                                         .count
    if pending_budgets > 0
      actions << {
        type: 'budget',
        title: 'Budgets à approuver', 
        count: pending_budgets,
        urgency: 'high',
        link: '/immo/promo/budgets/pending',
        icon: 'currency-dollar'
      }
    end
    
    # Risques critiques
    critical_risks = Immo::Promo::Risk.where(severity: 'critical', status: 'active')
                                      .joins(:project)
                                      .where(projects: { organization: user.organization })
                                      .count
    if critical_risks > 0
      actions << {
        type: 'risk',
        title: 'Risques critiques',
        count: critical_risks,
        urgency: 'critical',
        link: '/immo/promo/risks/critical',
        icon: 'exclamation-triangle'
      }
    end
    
    actions
  end
  
  def chef_projet_priority_actions
    actions = []
    
    # Tâches en retard
    overdue_tasks = Immo::Promo::Task.joins(:assignees)
                                     .where(assignees: { id: user.id })
                                     .where('due_date < ?', Date.current)
                                     .where.not(status: ['completed', 'cancelled'])
                                     .count
    if overdue_tasks > 0
      actions << {
        type: 'task',
        title: 'Tâches en retard',
        count: overdue_tasks,
        urgency: 'high',
        link: '/tasks/overdue',
        icon: 'clock'
      }
    end
    
    # Documents à valider (en tant que chef de projet)
    pending_reviews = Document.joins(:validation_requests)
                              .where(validation_requests: { reviewer: user, status: 'pending' })
                              .count
    if pending_reviews > 0
      actions << {
        type: 'document',
        title: 'Documents à réviser',
        count: pending_reviews,
        urgency: 'medium',
        link: '/documents/pending_review',
        icon: 'document-text'
      }
    end
    
    # Jalons approchants (7 jours)
    upcoming_milestones = Immo::Promo::Milestone.joins(phase: :project)
                                                .where(projects: { project_manager: user })
                                                .where(due_date: Date.current..7.days.from_now)
                                                .where.not(status: 'completed')
                                                .count
    if upcoming_milestones > 0
      actions << {
        type: 'milestone',
        title: 'Jalons cette semaine',
        count: upcoming_milestones,
        urgency: 'medium',
        link: '/milestones/upcoming',
        icon: 'flag'
      }
    end
    
    actions
  end
  
  def juriste_priority_actions
    actions = []
    
    # Permis arrivant à échéance (30 jours)
    expiring_permits = Immo::Promo::Permit.where(organization: user.organization)
                                          .where(expiry_date: Date.current..30.days.from_now)
                                          .where(status: 'active')
                                          .count
    if expiring_permits > 0
      actions << {
        type: 'permit',
        title: 'Permis à renouveler',
        count: expiring_permits,
        urgency: 'high',
        link: '/permits/expiring',
        icon: 'document-duplicate'
      }
    end
    
    # Contrats à valider juridiquement
    pending_contracts = Immo::Promo::Contract.where(legal_validation_status: 'pending')
                                             .where(organization: user.organization)
                                             .count
    if pending_contracts > 0
      actions << {
        type: 'contract',
        title: 'Contrats à valider',
        count: pending_contracts,
        urgency: 'high',
        link: '/contracts/pending_validation',
        icon: 'clipboard-check'
      }
    end
    
    # Documents réglementaires manquants
    missing_regulatory = Document.joins(:metadata)
                                 .where(metadata: { key: 'regulatory_required', value: 'true' })
                                 .where(metadata: { key: 'regulatory_provided', value: 'false' })
                                 .count
    if missing_regulatory > 0
      actions << {
        type: 'regulatory',
        title: 'Documents réglementaires manquants',
        count: missing_regulatory,
        urgency: 'medium',
        link: '/documents/regulatory/missing',
        icon: 'shield-exclamation'
      }
    end
    
    actions
  end
  
  def default_priority_actions
    # Actions de base pour tous les profils
    [
      {
        type: 'notification',
        title: 'Notifications non lues',
        count: user.notifications.unread.count,
        urgency: 'low',
        link: '/notifications',
        icon: 'bell'
      }
    ].reject { |action| action[:count] == 0 }
  end
  
  def navigation_items
    NavigationService.new(profile).personalized_items
  end
  
  def recent_notifications
    user.notifications.unread.limit(5).map do |notification|
      {
        id: notification.id,
        type: notification.notification_type,
        title: notification.title,
        message: notification.message,
        created_at: notification.created_at,
        urgency: notification.urgency
      }
    end
  end
  
  def key_metrics
    MetricsService.new(user, profile).dashboard_metrics
  end
end
```

#### Service de Widgets par Défaut

```ruby
# app/services/default_widget_service.rb
class DefaultWidgetService
  WIDGET_CONFIGS = {
    direction: [
      { type: 'portfolio_overview', width: 2, height: 1 },
      { type: 'financial_summary', width: 1, height: 1 },
      { type: 'risk_matrix', width: 1, height: 1 },
      { type: 'approval_queue', width: 1, height: 2 },
      { type: 'kpi_dashboard', width: 2, height: 1 },
      { type: 'team_performance', width: 1, height: 1 }
    ],
    chef_projet: [
      { type: 'project_timeline', width: 2, height: 2 },
      { type: 'task_kanban', width: 2, height: 2 },
      { type: 'team_availability', width: 1, height: 1 },
      { type: 'milestone_tracker', width: 1, height: 1 },
      { type: 'recent_documents', width: 2, height: 1 }
    ],
    juriste: [
      { type: 'permit_status', width: 2, height: 1 },
      { type: 'contract_tracker', width: 1, height: 1 },
      { type: 'compliance_dashboard', width: 1, height: 1 },
      { type: 'regulatory_calendar', width: 2, height: 1 },
      { type: 'legal_documents', width: 2, height: 1 }
    ],
    commercial: [
      { type: 'sales_pipeline', width: 2, height: 2 },
      { type: 'inventory_status', width: 1, height: 1 },
      { type: 'conversion_metrics', width: 1, height: 1 },
      { type: 'top_prospects', width: 1, height: 1 },
      { type: 'monthly_targets', width: 1, height: 1 }
    ],
    architecte: [
      { type: 'project_plans', width: 2, height: 2 },
      { type: 'pending_validations', width: 1, height: 1 },
      { type: 'modification_requests', width: 1, height: 1 },
      { type: 'technical_documents', width: 2, height: 1 }
    ],
    controleur: [
      { type: 'budget_variance', width: 2, height: 1 },
      { type: 'cash_flow', width: 1, height: 1 },
      { type: 'pending_invoices', width: 1, height: 1 },
      { type: 'cost_analysis', width: 2, height: 2 },
      { type: 'financial_alerts', width: 2, height: 1 }
    ]
  }.freeze
  
  def initialize(profile)
    @profile = profile
  end
  
  def generate_widgets
    base_widgets = WIDGET_CONFIGS[@profile.profile_type.to_sym] || default_widgets
    
    # Enrichir avec la configuration par défaut
    base_widgets.map do |widget|
      widget.merge(
        config: default_config_for(widget[:type]),
        visible: true
      )
    end
  end
  
  private
  
  def default_widgets
    [
      { type: 'recent_activity', width: 2, height: 1 },
      { type: 'my_documents', width: 2, height: 1 },
      { type: 'notifications_summary', width: 1, height: 1 },
      { type: 'quick_links', width: 1, height: 1 }
    ]
  end
  
  def default_config_for(widget_type)
    case widget_type
    when 'portfolio_overview'
      { 
        show_inactive: false, 
        group_by: 'status',
        refresh_interval: 300 # 5 minutes
      }
    when 'financial_summary'
      {
        currency: 'EUR',
        show_variance: true,
        comparison_period: 'month'
      }
    when 'task_kanban'
      {
        columns: ['todo', 'in_progress', 'review', 'done'],
        show_assignee: true,
        enable_drag_drop: true
      }
    else
      {}
    end
  end
end
```

### 1.3 Composants ViewComponent

#### Component de Base pour les Widgets

```ruby
# app/components/dashboard/widget_component.rb
class Dashboard::WidgetComponent < ApplicationComponent
  attr_reader :widget_data, :size, :loading, :error
  
  def initialize(widget_data:, size: { width: 1, height: 1 }, loading: false, error: nil)
    @widget_data = widget_data
    @size = size
    @loading = loading
    @error = error
  end
  
  private
  
  def widget_classes
    classes = ['dashboard-widget', 'bg-white', 'rounded-lg', 'shadow', 'p-4', 'relative']
    classes << "col-span-#{size[:width]}" if size[:width] > 1
    classes << "row-span-#{size[:height]}" if size[:height] > 1
    classes << 'animate-pulse' if loading
    classes << 'border-red-300' if error
    classes.join(' ')
  end
  
  def render_header?
    widget_data[:title].present? || widget_data[:actions].present?
  end
  
  def render_actions?
    widget_data[:actions].present? && !loading && !error
  end
end
```

```erb
<!-- app/components/dashboard/widget_component.html.erb -->
<div class="<%= widget_classes %>" data-widget-id="<%= widget_data[:id] %>">
  <% if loading %>
    <div class="space-y-3">
      <div class="h-4 bg-gray-200 rounded w-3/4"></div>
      <div class="h-20 bg-gray-200 rounded"></div>
      <div class="h-4 bg-gray-200 rounded w-1/2"></div>
    </div>
  <% elsif error %>
    <div class="text-center py-8">
      <svg class="mx-auto h-12 w-12 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <p class="mt-2 text-sm text-gray-600"><%= error %></p>
    </div>
  <% else %>
    <% if render_header? %>
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-medium text-gray-900">
          <%= widget_data[:title] %>
        </h3>
        <% if render_actions? %>
          <div class="flex space-x-2">
            <% widget_data[:actions].each do |action| %>
              <%= render UI::ButtonComponent.new(
                size: :sm,
                variant: :ghost,
                icon: action[:icon],
                data: { action: action[:type] }
              ) %>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>
    
    <div class="widget-content">
      <%= content %>
    </div>
    
    <% if widget_data[:footer] %>
      <div class="mt-4 pt-4 border-t border-gray-200">
        <%= widget_data[:footer] %>
      </div>
    <% end %>
  <% end %>
  
  <% if widget_data[:refreshable] %>
    <div class="absolute top-2 right-2">
      <button 
        class="text-gray-400 hover:text-gray-600" 
        data-action="refresh-widget"
        data-widget-id="<%= widget_data[:id] %>"
      >
        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
      </button>
    </div>
  <% end %>
</div>
```

#### Actions Panel Component

```ruby
# app/components/dashboard/actions_panel_component.rb
class Dashboard::ActionsPanelComponent < ApplicationComponent
  attr_reader :actions, :user, :collapsed
  
  def initialize(actions:, user:, collapsed: false)
    @actions = actions
    @user = user
    @collapsed = collapsed
  end
  
  private
  
  def grouped_actions
    @grouped_actions ||= actions.group_by { |action| action[:type] }
  end
  
  def urgency_color(urgency)
    case urgency
    when 'critical' then 'red'
    when 'high' then 'orange'
    when 'medium' then 'yellow'
    else 'gray'
    end
  end
  
  def urgency_classes(urgency)
    color = urgency_color(urgency)
    "bg-#{color}-100 text-#{color}-800 border-#{color}-200"
  end
  
  def total_actions_count
    actions.sum { |action| action[:count] || 0 }
  end
end
```

```erb
<!-- app/components/dashboard/actions_panel_component.html.erb -->
<div class="actions-panel <%= 'collapsed' if collapsed %>" data-controller="actions-panel">
  <div class="flex items-center justify-between p-4 border-b">
    <h2 class="text-lg font-semibold text-gray-900 <%= 'hidden' if collapsed %>">
      Actions prioritaires
    </h2>
    <button 
      data-action="click->actions-panel#toggle"
      class="p-1 rounded hover:bg-gray-100"
    >
      <svg class="h-5 w-5 text-gray-500 transform <%= 'rotate-180' if collapsed %>" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
      </svg>
    </button>
  </div>
  
  <div class="p-4 space-y-3 <%= 'hidden' if collapsed %>">
    <% if actions.empty? %>
      <div class="text-center py-8">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p class="mt-2 text-sm text-gray-600">Aucune action en attente</p>
      </div>
    <% else %>
      <% grouped_actions.each do |type, type_actions| %>
        <div class="space-y-2">
          <% type_actions.each do |action| %>
            <a 
              href="<%= action[:link] %>" 
              class="block p-3 rounded-lg border <%= urgency_classes(action[:urgency]) %> hover:shadow-md transition-shadow"
            >
              <div class="flex items-center justify-between">
                <div class="flex items-center space-x-3">
                  <div class="flex-shrink-0">
                    <%= render UI::IconComponent.new(
                      name: action[:icon],
                      size: :md,
                      class: "text-#{urgency_color(action[:urgency])}-600"
                    ) %>
                  </div>
                  <div>
                    <p class="text-sm font-medium"><%= action[:title] %></p>
                    <% if action[:subtitle] %>
                      <p class="text-xs text-gray-600"><%= action[:subtitle] %></p>
                    <% end %>
                  </div>
                </div>
                <% if action[:count] && action[:count] > 0 %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-<%= urgency_color(action[:urgency]) %>-600 text-white">
                    <%= action[:count] %>
                  </span>
                <% end %>
              </div>
            </a>
          <% end %>
        </div>
      <% end %>
    <% end %>
  </div>
  
  <% if collapsed && total_actions_count > 0 %>
    <div class="p-2">
      <div class="relative">
        <span class="absolute -top-1 -right-1 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white bg-red-600 rounded-full">
          <%= total_actions_count %>
        </span>
      </div>
    </div>
  <% end %>
</div>
```

### 1.4 Controllers et Routes

#### Dashboard Controller

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_profile
  
  def index
    @dashboard_service = DashboardPersonalizationService.new(current_user)
    @dashboard_data = @dashboard_service.dashboard_data
    
    respond_to do |format|
      format.html
      format.json { render json: @dashboard_data }
    end
  end
  
  def update_widget
    widget = current_user.active_profile.dashboard_widgets.find(params[:id])
    
    if widget.update(widget_params)
      render json: { status: 'success', widget: widget_data(widget) }
    else
      render json: { status: 'error', errors: widget.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def reorder_widgets
    widgets = current_user.active_profile.dashboard_widgets
    
    params[:positions].each do |widget_id, position|
      widgets.find(widget_id).update(position: position)
    end
    
    render json: { status: 'success' }
  end
  
  def refresh_widget
    widget = current_user.active_profile.dashboard_widgets.find(params[:id])
    data = load_widget_data(widget)
    
    render json: { status: 'success', data: data }
  end
  
  private
  
  def ensure_user_profile
    unless current_user.active_profile
      # Créer un profil par défaut basé sur le rôle
      profile_type = detect_profile_type(current_user)
      current_user.user_profiles.create!(
        profile_type: profile_type,
        active: true
      )
    end
  end
  
  def detect_profile_type(user)
    # Logique pour déterminer le type de profil basé sur les permissions
    if user.super_admin?
      'direction'
    elsif user.has_permission?('immo_promo:manage')
      'chef_projet'
    elsif user.has_permission?('legal:manage')
      'juriste'
    elsif user.has_permission?('commercial:manage')
      'commercial'
    else
      'user'
    end
  end
  
  def widget_params
    params.require(:widget).permit(:visible, :width, :height, config: {})
  end
  
  def load_widget_data(widget)
    widget_class = "Widgets::#{widget.widget_type.camelize}Widget".constantize
    widget_instance = widget_class.new(current_user, widget.config)
    widget_instance.data
  rescue NameError
    { error: "Widget non disponible" }
  end
  
  def widget_data(widget)
    {
      id: widget.id,
      type: widget.widget_type,
      position: widget.position,
      size: { width: widget.width, height: widget.height },
      config: widget.config,
      data: load_widget_data(widget)
    }
  end
end
```

#### Routes Configuration

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ... autres routes ...
  
  # Dashboard personnalisé (nouvelle page d'accueil)
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end
  
  resource :dashboard, only: [:index] do
    member do
      patch 'widgets/:id', to: 'dashboard#update_widget', as: :update_widget
      post 'widgets/reorder', to: 'dashboard#reorder_widgets', as: :reorder_widgets
      post 'widgets/:id/refresh', to: 'dashboard#refresh_widget', as: :refresh_widget
    end
  end
  
  # API endpoints pour le dashboard
  namespace :api do
    namespace :v1 do
      resource :dashboard do
        get 'widgets'
        get 'actions'
        get 'notifications'
        get 'metrics'
      end
    end
  end
  
  # ... autres routes ...
end
```

### 1.5 JavaScript Controllers (Stimulus)

#### Dashboard Controller

```javascript
// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["widgetGrid", "actionPanel", "notification"]
  static values = { 
    refreshInterval: Number,
    updateUrl: String
  }
  
  connect() {
    this.initializeSortable()
    this.startAutoRefresh()
    this.setupEventListeners()
  }
  
  disconnect() {
    this.stopAutoRefresh()
    if (this.sortable) {
      this.sortable.destroy()
    }
  }
  
  initializeSortable() {
    if (this.hasWidgetGridTarget) {
      this.sortable = Sortable.create(this.widgetGridTarget, {
        animation: 150,
        handle: ".widget-handle",
        ghostClass: "widget-ghost",
        onEnd: this.handleReorder.bind(this)
      })
    }
  }
  
  handleReorder(event) {
    const positions = {}
    const widgets = this.widgetGridTarget.querySelectorAll("[data-widget-id]")
    
    widgets.forEach((widget, index) => {
      positions[widget.dataset.widgetId] = index
    })
    
    fetch(`${this.updateUrlValue}/reorder`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ positions })
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === "success") {
        this.showNotification("Widgets réorganisés", "success")
      }
    })
    .catch(error => {
      console.error("Erreur lors de la réorganisation:", error)
      this.showNotification("Erreur lors de la réorganisation", "error")
    })
  }
  
  refreshWidget(event) {
    const widgetId = event.currentTarget.dataset.widgetId
    const widget = document.querySelector(`[data-widget-id="${widgetId}"]`)
    
    // Ajouter état de chargement
    widget.classList.add("loading")
    
    fetch(`${this.updateUrlValue}/${widgetId}/refresh`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === "success") {
        // Mettre à jour le contenu du widget
        this.updateWidgetContent(widgetId, data.data)
      }
    })
    .finally(() => {
      widget.classList.remove("loading")
    })
  }
  
  updateWidgetContent(widgetId, data) {
    const widget = document.querySelector(`[data-widget-id="${widgetId}"]`)
    const content = widget.querySelector(".widget-content")
    
    // Utiliser Turbo pour mettre à jour le contenu
    // Ceci nécessiterait un partial côté serveur
    content.innerHTML = this.renderWidgetContent(data)
  }
  
  startAutoRefresh() {
    if (this.refreshIntervalValue > 0) {
      this.refreshTimer = setInterval(() => {
        this.refreshDashboard()
      }, this.refreshIntervalValue * 1000)
    }
  }
  
  stopAutoRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
  
  refreshDashboard() {
    // Rafraîchir les widgets marqués comme auto-refresh
    document.querySelectorAll("[data-auto-refresh='true']").forEach(widget => {
      this.refreshWidget({ currentTarget: widget })
    })
  }
  
  showNotification(message, type = "info") {
    // Implémenter la notification (peut utiliser un autre contrôleur Stimulus)
    console.log(`${type}: ${message}`)
  }
  
  setupEventListeners() {
    // Écouter les événements de refresh des widgets
    document.addEventListener("dashboard:refresh-widget", (event) => {
      this.refreshWidget({ currentTarget: event.detail.widget })
    })
    
    // Écouter les changements de configuration
    document.addEventListener("dashboard:config-changed", (event) => {
      this.handleConfigChange(event.detail)
    })
  }
  
  handleConfigChange(detail) {
    // Gérer les changements de configuration
    console.log("Configuration changed:", detail)
  }
}
```

#### Actions Panel Controller

```javascript
// app/javascript/controllers/actions_panel_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "content", "toggleButton", "badge"]
  static classes = ["collapsed", "expanded"]
  static values = { collapsed: Boolean }
  
  connect() {
    this.loadState()
    this.updateBadge()
  }
  
  toggle() {
    this.collapsedValue = !this.collapsedValue
    this.saveState()
    this.updateView()
  }
  
  updateView() {
    if (this.collapsedValue) {
      this.panelTarget.classList.add(this.collapsedClass)
      this.panelTarget.classList.remove(this.expandedClass)
      this.contentTarget.classList.add("hidden")
    } else {
      this.panelTarget.classList.remove(this.collapsedClass)
      this.panelTarget.classList.add(this.expandedClass)
      this.contentTarget.classList.remove("hidden")
    }
    
    // Rotation de l'icône
    const icon = this.toggleButtonTarget.querySelector("svg")
    if (icon) {
      icon.classList.toggle("rotate-180", this.collapsedValue)
    }
  }
  
  loadState() {
    const saved = localStorage.getItem("actionsPanelCollapsed")
    if (saved !== null) {
      this.collapsedValue = saved === "true"
      this.updateView()
    }
  }
  
  saveState() {
    localStorage.setItem("actionsPanelCollapsed", this.collapsedValue)
  }
  
  updateBadge() {
    if (this.hasBadgeTarget) {
      const count = this.element.querySelectorAll("[data-action-item]").length
      this.badgeTarget.textContent = count
      this.badgeTarget.classList.toggle("hidden", count === 0)
    }
  }
  
  markAsRead(event) {
    const item = event.currentTarget.closest("[data-action-item]")
    const actionId = item.dataset.actionId
    
    // Marquer comme lu côté serveur
    fetch(`/api/v1/actions/${actionId}/mark_read`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    })
    .then(() => {
      item.remove()
      this.updateBadge()
    })
  }
}
```

### 1.6 Styles et Design System

#### Tailwind Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/components/**/*.{html.erb,rb}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      gridTemplateColumns: {
        'dashboard': 'repeat(auto-fit, minmax(300px, 1fr))',
        'dashboard-lg': 'repeat(4, 1fr)',
      },
      animation: {
        'slide-in': 'slideIn 0.3s ease-out',
        'fade-in': 'fadeIn 0.3s ease-out',
      },
      keyframes: {
        slideIn: {
          '0%': { transform: 'translateX(-100%)' },
          '100%': { transform: 'translateX(0)' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        }
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

#### Styles Dashboard

```scss
// app/assets/stylesheets/dashboard.scss
.dashboard-container {
  @apply min-h-screen bg-gray-50;
  
  .dashboard-grid {
    @apply grid gap-6;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    
    @screen lg {
      grid-template-columns: repeat(4, 1fr);
    }
  }
  
  .dashboard-widget {
    @apply transition-all duration-200;
    
    &.loading {
      @apply opacity-50;
      pointer-events: none;
    }
    
    &.widget-ghost {
      @apply opacity-25 bg-blue-100 border-2 border-blue-300 border-dashed;
    }
    
    .widget-handle {
      @apply cursor-move;
    }
    
    &:hover {
      @apply shadow-lg;
      
      .widget-actions {
        @apply opacity-100;
      }
    }
    
    .widget-actions {
      @apply opacity-0 transition-opacity duration-200;
    }
  }
  
  .actions-panel {
    @apply bg-white shadow-lg transition-all duration-300;
    width: 320px;
    
    &.collapsed {
      width: 60px;
      
      .panel-content {
        @apply hidden;
      }
    }
  }
}

// Animations
@keyframes pulse-soft {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.animate-pulse-soft {
  animation: pulse-soft 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

// Urgency indicators
.urgency-critical {
  @apply border-red-500 bg-red-50;
  
  &::before {
    content: '';
    @apply absolute top-0 right-0 w-3 h-3 bg-red-500 rounded-full animate-pulse;
  }
}

.urgency-high {
  @apply border-orange-500 bg-orange-50;
}

.urgency-medium {
  @apply border-yellow-500 bg-yellow-50;
}

.urgency-low {
  @apply border-gray-300 bg-gray-50;
}
```

### 1.7 Tests RSpec

#### Tests du Service de Personnalisation

```ruby
# spec/services/dashboard_personalization_service_spec.rb
require 'rails_helper'

RSpec.describe DashboardPersonalizationService do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:service) { described_class.new(user) }
  
  describe '#dashboard_data' do
    context 'with direction profile' do
      let!(:profile) { create(:user_profile, user: user, profile_type: 'direction') }
      
      before do
        # Créer des données de test
        create_list(:validation_request, 3, reviewer: user, status: 'pending')
        create_list(:budget, 2, status: 'pending_approval', project: create(:project, organization: organization))
        create(:risk, severity: 'critical', status: 'active', project: create(:project, organization: organization))
      end
      
      it 'returns direction-specific widgets' do
        data = service.dashboard_data
        
        expect(data[:widgets]).to include(
          a_hash_including(type: 'portfolio_overview'),
          a_hash_including(type: 'financial_summary'),
          a_hash_including(type: 'risk_matrix')
        )
      end
      
      it 'includes priority actions for direction' do
        data = service.dashboard_data
        actions = data[:actions]
        
        expect(actions).to include(
          a_hash_including(type: 'validation', count: 3),
          a_hash_including(type: 'budget', count: 2),
          a_hash_including(type: 'risk', count: 1)
        )
      end
    end
    
    context 'with chef_projet profile' do
      let!(:profile) { create(:user_profile, user: user, profile_type: 'chef_projet') }
      
      before do
        project = create(:project, project_manager: user, organization: organization)
        create_list(:task, 5, :overdue, assignees: [user], phase: create(:phase, project: project))
        create_list(:milestone, 2, :upcoming, phase: create(:phase, project: project))
      end
      
      it 'returns chef_projet-specific widgets' do
        data = service.dashboard_data
        
        expect(data[:widgets]).to include(
          a_hash_including(type: 'project_timeline'),
          a_hash_including(type: 'task_kanban'),
          a_hash_including(type: 'milestone_tracker')
        )
      end
      
      it 'includes overdue tasks in priority actions' do
        data = service.dashboard_data
        actions = data[:actions]
        
        expect(actions).to include(
          a_hash_including(type: 'task', title: 'Tâches en retard', count: 5)
        )
      end
    end
  end
  
  describe '#priority_actions' do
    context 'urgency levels' do
      let!(:profile) { create(:user_profile, user: user, profile_type: 'direction') }
      
      before do
        create_list(:risk, 3, severity: 'critical', status: 'active', 
                    project: create(:project, organization: organization))
      end
      
      it 'assigns correct urgency levels' do
        actions = service.priority_actions
        risk_action = actions.find { |a| a[:type] == 'risk' }
        
        expect(risk_action[:urgency]).to eq('critical')
      end
    end
  end
end
```

#### Tests des Composants

```ruby
# spec/components/dashboard/widget_component_spec.rb
require 'rails_helper'

RSpec.describe Dashboard::WidgetComponent, type: :component do
  let(:widget_data) do
    {
      id: 1,
      type: 'test_widget',
      title: 'Test Widget',
      actions: [
        { icon: 'refresh', type: 'refresh' },
        { icon: 'cog', type: 'settings' }
      ]
    }
  end
  
  context 'with normal state' do
    it 'renders widget with title and actions' do
      render_inline(described_class.new(widget_data: widget_data)) do
        "Widget content"
      end
      
      expect(page).to have_text('Test Widget')
      expect(page).to have_text('Widget content')
      expect(page).to have_css('[data-widget-id="1"]')
      expect(page).to have_css('button', count: 2)
    end
  end
  
  context 'with loading state' do
    it 'renders loading skeleton' do
      render_inline(described_class.new(widget_data: widget_data, loading: true))
      
      expect(page).to have_css('.animate-pulse')
      expect(page).not_to have_text('Test Widget')
    end
  end
  
  context 'with error state' do
    it 'renders error message' do
      render_inline(described_class.new(
        widget_data: widget_data,
        error: "Erreur de chargement"
      ))
      
      expect(page).to have_text('Erreur de chargement')
      expect(page).to have_css('.border-red-300')
    end
  end
  
  context 'with different sizes' do
    it 'applies correct grid classes' do
      render_inline(described_class.new(
        widget_data: widget_data,
        size: { width: 2, height: 2 }
      ))
      
      expect(page).to have_css('.col-span-2.row-span-2')
    end
  end
end
```

## 📊 Phase 2 : Dashboards Personnalisés par Profil

### 2.1 Widgets Spécifiques par Profil

#### Widget Portfolio Overview (Direction)

```ruby
# app/models/widgets/portfolio_overview_widget.rb
module Widgets
  class PortfolioOverviewWidget < BaseWidget
    def data
      {
        title: "Vue d'ensemble du portfolio",
        type: "portfolio_overview",
        refreshable: true,
        actions: [
          { icon: 'filter', type: 'filter' },
          { icon: 'download', type: 'export' }
        ],
        content: {
          summary: portfolio_summary,
          projects: active_projects,
          charts: {
            status_distribution: status_chart_data,
            budget_allocation: budget_chart_data,
            timeline_overview: timeline_data
          }
        }
      }
    end
    
    private
    
    def portfolio_summary
      projects = organization_projects
      
      {
        total_projects: projects.count,
        active_projects: projects.active.count,
        total_budget: projects.sum(:total_budget_cents) / 100,
        total_invested: projects.sum(:spent_amount_cents) / 100,
        completion_rate: calculate_average_completion(projects),
        at_risk_count: projects.joins(:risks).where(risks: { severity: 'critical', status: 'active' }).distinct.count
      }
    end
    
    def active_projects
      organization_projects.active.includes(:project_manager, :phases).map do |project|
        {
          id: project.id,
          name: project.name,
          status: project.status,
          completion: project.completion_percentage,
          budget_health: calculate_budget_health(project),
          manager: project.project_manager.name,
          next_milestone: project.next_milestone&.name,
          risk_level: project.overall_risk_level,
          trend: calculate_trend(project)
        }
      end
    end
    
    def status_chart_data
      organization_projects.group(:status).count.map do |status, count|
        {
          name: I18n.t("project.status.#{status}"),
          value: count,
          color: status_color(status)
        }
      end
    end
    
    def budget_chart_data
      organization_projects.active.map do |project|
        {
          name: project.name,
          budget: project.total_budget_cents / 100,
          spent: project.spent_amount_cents / 100,
          committed: project.committed_amount_cents / 100
        }
      end
    end
    
    def timeline_data
      projects = organization_projects.active.includes(:phases)
      
      {
        projects: projects.map do |project|
          {
            id: project.id,
            name: project.name,
            start_date: project.start_date,
            end_date: project.end_date,
            phases: project.phases.map do |phase|
              {
                name: phase.name,
                start_date: phase.start_date,
                end_date: phase.end_date,
                status: phase.status,
                completion: phase.completion_percentage
              }
            end
          }
        end
      }
    end
    
    def organization_projects
      @organization_projects ||= Immo::Promo::Project.where(organization: user.organization)
    end
    
    def calculate_budget_health(project)
      return 'healthy' if project.budget_variance_percentage.abs < 5
      return 'warning' if project.budget_variance_percentage.abs < 15
      'critical'
    end
    
    def calculate_trend(project)
      # Logique pour calculer la tendance basée sur l'historique
      'stable'
    end
    
    def status_color(status)
      {
        'planning' => '#3B82F6',
        'in_progress' => '#10B981',
        'on_hold' => '#F59E0B',
        'completed' => '#6B7280',
        'cancelled' => '#EF4444'
      }[status] || '#6B7280'
    end
    
    def calculate_average_completion(projects)
      return 0 if projects.empty?
      projects.average(:completion_percentage)&.round || 0
    end
  end
end
```

#### Widget Task Kanban (Chef de Projet)

```ruby
# app/models/widgets/task_kanban_widget.rb
module Widgets
  class TaskKanbanWidget < BaseWidget
    COLUMNS = ['todo', 'in_progress', 'review', 'done'].freeze
    
    def data
      {
        title: "Tableau des tâches",
        type: "task_kanban",
        refreshable: true,
        actions: [
          { icon: 'plus', type: 'add_task' },
          { icon: 'filter', type: 'filter' },
          { icon: 'view-grid', type: 'change_view' }
        ],
        content: {
          columns: kanban_columns,
          stats: task_statistics,
          filters: active_filters
        },
        config: {
          enable_drag_drop: true,
          show_assignee: true,
          show_priority: true,
          show_due_date: true
        }
      }
    end
    
    private
    
    def kanban_columns
      COLUMNS.map do |status|
        {
          id: status,
          title: I18n.t("task.status.#{status}"),
          color: column_color(status),
          tasks: tasks_for_column(status),
          count: tasks_for_column(status).count,
          wip_limit: wip_limit_for(status),
          actions: column_actions(status)
        }
      end
    end
    
    def tasks_for_column(status)
      tasks.where(status: status).includes(:assignees, :phase).map do |task|
        {
          id: task.id,
          title: task.name,
          description: task.description&.truncate(100),
          priority: task.priority,
          due_date: task.due_date,
          overdue: task.overdue?,
          assignees: task.assignees.map { |a| 
            {
              id: a.id,
              name: a.name,
              avatar_url: a.avatar_url
            }
          },
          phase: {
            id: task.phase.id,
            name: task.phase.name,
            color: task.phase.color
          },
          labels: task.labels,
          progress: task.progress_percentage,
          blocked: task.blocked?,
          blocking_reason: task.blocking_reason
        }
      end
    end
    
    def task_statistics
      {
        total: tasks.count,
        completed_this_week: tasks.where(
          status: 'done',
          updated_at: 1.week.ago..Time.current
        ).count,
        overdue: tasks.overdue.count,
        blocked: tasks.blocked.count,
        my_tasks: tasks.joins(:assignees).where(assignees: { id: user.id }).count,
        unassigned: tasks.left_joins(:task_assignments).where(task_assignments: { id: nil }).count
      }
    end
    
    def active_filters
      {
        projects: user_projects.pluck(:id),
        assignees: config[:filter_assignees] || [],
        priorities: config[:filter_priorities] || [],
        due_date_range: config[:filter_due_date] || 'all'
      }
    end
    
    def tasks
      @tasks ||= begin
        base_query = Immo::Promo::Task.joins(phase: :project)
                                      .where(projects: { id: user_projects.pluck(:id) })
        
        # Appliquer les filtres
        base_query = apply_filters(base_query)
        base_query.order(priority: :desc, due_date: :asc)
      end
    end
    
    def user_projects
      @user_projects ||= if user.super_admin?
        Immo::Promo::Project.where(organization: user.organization)
      else
        Immo::Promo::Project.where(project_manager: user)
                            .or(Immo::Promo::Project.joins(:stakeholders)
                            .where(stakeholders: { user: user }))
      end
    end
    
    def apply_filters(query)
      # Filtrer par assignés
      if config[:filter_assignees].present?
        query = query.joins(:assignees).where(assignees: { id: config[:filter_assignees] })
      end
      
      # Filtrer par priorité
      if config[:filter_priorities].present?
        query = query.where(priority: config[:filter_priorities])
      end
      
      # Filtrer par date d'échéance
      case config[:filter_due_date]
      when 'overdue'
        query = query.where('due_date < ?', Date.current)
      when 'today'
        query = query.where(due_date: Date.current)
      when 'this_week'
        query = query.where(due_date: Date.current..Date.current.end_of_week)
      when 'this_month'
        query = query.where(due_date: Date.current..Date.current.end_of_month)
      end
      
      query
    end
    
    def column_color(status)
      {
        'todo' => 'gray',
        'in_progress' => 'blue',
        'review' => 'yellow',
        'done' => 'green'
      }[status]
    end
    
    def wip_limit_for(status)
      {
        'todo' => nil,
        'in_progress' => 5,
        'review' => 3,
        'done' => nil
      }[status]
    end
    
    def column_actions(status)
      actions = []
      actions << { icon: 'plus', type: 'add_task', label: 'Ajouter une tâche' } if status == 'todo'
      actions << { icon: 'archive', type: 'archive_all', label: 'Archiver terminées' } if status == 'done'
      actions
    end
  end
end
```

#### Widget Permit Status (Juriste)

```ruby
# app/models/widgets/permit_status_widget.rb
module Widgets
  class PermitStatusWidget < BaseWidget
    def data
      {
        title: "Suivi des permis et autorisations",
        type: "permit_status",
        refreshable: true,
        actions: [
          { icon: 'plus', type: 'add_permit' },
          { icon: 'calendar', type: 'timeline_view' },
          { icon: 'download', type: 'export_report' }
        ],
        content: {
          summary: permit_summary,
          critical_permits: critical_permits,
          timeline: permit_timeline,
          by_project: permits_by_project
        }
      }
    end
    
    private
    
    def permit_summary
      all_permits = organization_permits
      
      {
        total: all_permits.count,
        active: all_permits.active.count,
        pending: all_permits.pending.count,
        expiring_soon: all_permits.expiring_within(30.days).count,
        expired: all_permits.expired.count,
        with_conditions: all_permits.joins(:permit_conditions).distinct.count,
        compliance_rate: calculate_compliance_rate(all_permits)
      }
    end
    
    def critical_permits
      organization_permits.includes(:project, :permit_conditions)
                          .where(permit_type: critical_permit_types)
                          .or(organization_permits.expiring_within(15.days))
                          .map do |permit|
        {
          id: permit.id,
          number: permit.permit_number,
          type: permit.permit_type,
          project: {
            id: permit.project.id,
            name: permit.project.name
          },
          status: permit.status,
          issue_date: permit.issue_date,
          expiry_date: permit.expiry_date,
          days_until_expiry: permit.days_until_expiry,
          conditions_count: permit.permit_conditions.count,
          uncompleted_conditions: permit.permit_conditions.pending.count,
          risk_level: assess_permit_risk(permit),
          actions_required: required_actions_for(permit)
        }
      end
    end
    
    def permit_timeline
      upcoming_dates = []
      
      # Échéances de permis
      organization_permits.active.each do |permit|
        if permit.expiry_date.present?
          upcoming_dates << {
            date: permit.expiry_date,
            type: 'permit_expiry',
            title: "Expiration : #{permit.permit_number}",
            project: permit.project.name,
            urgency: calculate_urgency(permit.expiry_date),
            action: "Renouveler le permis"
          }
        end
        
        # Conditions à respecter
        permit.permit_conditions.pending.each do |condition|
          if condition.deadline.present?
            upcoming_dates << {
              date: condition.deadline,
              type: 'condition_deadline',
              title: "Condition : #{condition.description.truncate(50)}",
              project: permit.project.name,
              urgency: calculate_urgency(condition.deadline),
              action: "Compléter la condition"
            }
          end
        end
      end
      
      # Trier par date
      upcoming_dates.sort_by { |item| item[:date] }
                    .first(20) # Limiter à 20 items
    end
    
    def permits_by_project
      Immo::Promo::Project.joins(:permits)
                          .where(organization: user.organization)
                          .distinct
                          .map do |project|
        permits = project.permits
        {
          project_id: project.id,
          project_name: project.name,
          project_status: project.status,
          permits: {
            total: permits.count,
            active: permits.active.count,
            pending: permits.pending.count,
            issues: count_permit_issues(permits)
          },
          compliance_score: calculate_project_compliance(project),
          next_action: next_required_action(project)
        }
      end
    end
    
    def organization_permits
      @organization_permits ||= Immo::Promo::Permit.joins(:project)
                                                   .where(projects: { organization: user.organization })
    end
    
    def critical_permit_types
      ['building_permit', 'environmental_permit', 'demolition_permit']
    end
    
    def assess_permit_risk(permit)
      return 'critical' if permit.expired?
      return 'high' if permit.expiring_within?(15.days)
      return 'medium' if permit.permit_conditions.pending.any?(&:overdue?)
      return 'low' if permit.expiring_within?(60.days)
      'none'
    end
    
    def required_actions_for(permit)
      actions = []
      
      if permit.expired?
        actions << { type: 'renew', label: 'Renouveler immédiatement', urgency: 'critical' }
      elsif permit.expiring_within?(30.days)
        actions << { type: 'prepare_renewal', label: 'Préparer renouvellement', urgency: 'high' }
      end
      
      if permit.permit_conditions.pending.any?
        actions << { 
          type: 'complete_conditions', 
          label: "Compléter #{permit.permit_conditions.pending.count} condition(s)",
          urgency: 'medium'
        }
      end
      
      actions
    end
    
    def calculate_urgency(date)
      days_until = (date - Date.current).to_i
      
      return 'critical' if days_until < 0
      return 'high' if days_until <= 7
      return 'medium' if days_until <= 30
      'low'
    end
    
    def calculate_compliance_rate(permits)
      return 0 if permits.empty?
      
      compliant_count = permits.select { |p| p.fully_compliant? }.count
      ((compliant_count.to_f / permits.count) * 100).round
    end
    
    def count_permit_issues(permits)
      permits.sum do |permit|
        issues = 0
        issues += 1 if permit.expired?
        issues += 1 if permit.expiring_within?(30.days)
        issues += permit.permit_conditions.pending.overdue.count
        issues
      end
    end
    
    def calculate_project_compliance(project)
      permits = project.permits
      return 100 if permits.empty?
      
      total_score = permits.sum do |permit|
        score = 100
        score -= 50 if permit.expired?
        score -= 25 if permit.expiring_within?(30.days)
        score -= (permit.permit_conditions.pending.count * 5)
        [score, 0].max
      end
      
      (total_score.to_f / permits.count).round
    end
    
    def next_required_action(project)
      # Logique pour déterminer la prochaine action requise
      urgent_permit = project.permits.find(&:expired?)
      return "Renouveler permis expiré" if urgent_permit
      
      expiring_permit = project.permits.find { |p| p.expiring_within?(30.days) }
      return "Préparer renouvellement permis" if expiring_permit
      
      overdue_condition = project.permits
                                 .flat_map(&:permit_conditions)
                                 .find(&:overdue?)
      return "Compléter condition en retard" if overdue_condition
      
      nil
    end
  end
end
```

### 2.2 Vue Dashboard Principale

```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="dashboard-container" data-controller="dashboard" data-dashboard-refresh-interval-value="300" data-dashboard-update-url-value="<%= dashboard_path %>">
  <!-- Navbar adaptative -->
  <%= render Navigation::NavbarComponent.new(
    user: current_user,
    navigation_items: @dashboard_data[:navigation]
  ) %>
  
  <div class="flex h-screen pt-16"> <!-- pt-16 pour compenser la navbar fixed -->
    <!-- Actions Panel -->
    <aside class="actions-panel bg-white shadow-lg" data-controller="actions-panel">
      <%= render Dashboard::ActionsPanelComponent.new(
        actions: @dashboard_data[:actions],
        user: current_user
      ) %>
    </aside>
    
    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900">
            <%= t('dashboard.welcome', name: current_user.first_name) %>
          </h1>
          <p class="mt-2 text-gray-600">
            <%= t("dashboard.subtitle.#{current_user.active_profile.profile_type}") %>
          </p>
        </div>
        
        <!-- Quick Stats -->
        <% if @dashboard_data[:metrics].present? %>
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
            <% @dashboard_data[:metrics].each do |metric| %>
              <%= render UI::MetricCardComponent.new(
                title: metric[:title],
                value: metric[:value],
                change: metric[:change],
                trend: metric[:trend],
                icon: metric[:icon]
              ) %>
            <% end %>
          </div>
        <% end %>
        
        <!-- Widgets Grid -->
        <div class="dashboard-grid" data-dashboard-target="widgetGrid">
          <% @dashboard_data[:widgets].each do |widget| %>
            <%= render Dashboard::WidgetComponent.new(
              widget_data: widget[:data],
              size: widget[:size]
            ) do %>
              <%= render "widgets/#{widget[:type]}", widget: widget[:data] %>
            <% end %>
          <% end %>
        </div>
      </div>
    </main>
  </div>
  
  <!-- Notifications Toast Container -->
  <div class="fixed bottom-4 right-4 z-50" data-dashboard-target="notification">
    <!-- Les notifications apparaîtront ici -->
  </div>
</div>

<!-- Configuration Modal -->
<%= render UI::ModalComponent.new(
  id: 'dashboard-config-modal',
  title: 'Configuration du tableau de bord'
) do %>
  <div class="space-y-4">
    <div>
      <h3 class="text-lg font-medium">Widgets disponibles</h3>
      <div class="mt-2 grid grid-cols-2 gap-2">
        <% current_user.active_profile.available_widgets.each do |widget| %>
          <label class="flex items-center space-x-2">
            <input type="checkbox" class="rounded" />
            <span class="text-sm"><%= widget[:name] %></span>
          </label>
        <% end %>
      </div>
    </div>
    
    <div>
      <h3 class="text-lg font-medium">Fréquence de rafraîchissement</h3>
      <select class="mt-1 block w-full rounded-md border-gray-300">
        <option value="0">Désactivé</option>
        <option value="60">1 minute</option>
        <option value="300" selected>5 minutes</option>
        <option value="600">10 minutes</option>
      </select>
    </div>
  </div>
<% end %>
```

### 2.3 Partials pour les Widgets

#### Widget Portfolio Overview

```erb
<!-- app/views/widgets/_portfolio_overview.html.erb -->
<div class="portfolio-overview-widget">
  <!-- Summary Cards -->
  <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
    <div class="bg-blue-50 rounded-lg p-4">
      <div class="text-sm text-blue-600 font-medium">Total Projets</div>
      <div class="text-2xl font-bold text-blue-900"><%= widget[:content][:summary][:total_projects] %></div>
    </div>
    <div class="bg-green-50 rounded-lg p-4">
      <div class="text-sm text-green-600 font-medium">Projets Actifs</div>
      <div class="text-2xl font-bold text-green-900"><%= widget[:content][:summary][:active_projects] %></div>
    </div>
    <div class="bg-yellow-50 rounded-lg p-4">
      <div class="text-sm text-yellow-600 font-medium">Budget Total</div>
      <div class="text-2xl font-bold text-yellow-900"><%= number_to_currency(widget[:content][:summary][:total_budget], unit: "€") %></div>
    </div>
    <div class="bg-red-50 rounded-lg p-4">
      <div class="text-sm text-red-600 font-medium">Projets à Risque</div>
      <div class="text-2xl font-bold text-red-900"><%= widget[:content][:summary][:at_risk_count] %></div>
    </div>
  </div>
  
  <!-- Projects Table -->
  <div class="overflow-hidden">
    <table class="min-w-full divide-y divide-gray-200">
      <thead class="bg-gray-50">
        <tr>
          <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Projet</th>
          <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
          <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Avancement</th>
          <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Budget</th>
          <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Risque</th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        <% widget[:content][:projects].each do |project| %>
          <tr class="hover:bg-gray-50 cursor-pointer" onclick="window.location.href='/immo/promo/projects/<%= project[:id] %>'">
            <td class="px-4 py-3">
              <div>
                <div class="text-sm font-medium text-gray-900"><%= project[:name] %></div>
                <div class="text-xs text-gray-500"><%= project[:manager] %></div>
              </div>
            </td>
            <td class="px-4 py-3">
              <%= render UI::StatusBadgeComponent.new(
                status: project[:status],
                size: :sm
              ) %>
            </td>
            <td class="px-4 py-3">
              <div class="flex items-center">
                <div class="flex-1 mr-2">
                  <%= render UI::ProgressBarComponent.new(
                    percentage: project[:completion],
                    size: :sm
                  ) %>
                </div>
                <span class="text-xs text-gray-600"><%= project[:completion] %>%</span>
              </div>
            </td>
            <td class="px-4 py-3">
              <div class="flex items-center">
                <span class="w-2 h-2 rounded-full mr-2 bg-<%= budget_health_color(project[:budget_health]) %>-400"></span>
                <span class="text-sm text-gray-900"><%= project[:budget_health].capitalize %></span>
              </div>
            </td>
            <td class="px-4 py-3">
              <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-<%= risk_level_color(project[:risk_level]) %>-100 text-<%= risk_level_color(project[:risk_level]) %>-800">
                <%= project[:risk_level].capitalize %>
              </span>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
  
  <!-- Charts Section -->
  <div class="mt-6 grid grid-cols-1 md:grid-cols-2 gap-6">
    <div>
      <h4 class="text-sm font-medium text-gray-700 mb-3">Répartition par statut</h4>
      <%= render UI::ChartComponent.new(
        type: 'donut',
        data: widget[:content][:charts][:status_distribution],
        height: 200
      ) %>
    </div>
    <div>
      <h4 class="text-sm font-medium text-gray-700 mb-3">Allocation budgétaire</h4>
      <%= render UI::ChartComponent.new(
        type: 'bar',
        data: widget[:content][:charts][:budget_allocation],
        height: 200
      ) %>
    </div>
  </div>
</div>

<style>
.portfolio-overview-widget {
  min-height: 400px;
}
</style>
```

#### Widget Task Kanban

```erb
<!-- app/views/widgets/_task_kanban.html.erb -->
<div class="task-kanban-widget" data-controller="kanban" data-kanban-update-url="<%= api_v1_tasks_reorder_path %>">
  <!-- Kanban Header -->
  <div class="flex items-center justify-between mb-4">
    <div class="flex items-center space-x-4">
      <select class="text-sm border-gray-300 rounded-md" data-action="change->kanban#filterByProject">
        <option value="">Tous les projets</option>
        <% current_user.accessible_projects.each do |project| %>
          <option value="<%= project.id %>"><%= project.name %></option>
        <% end %>
      </select>
      
      <select class="text-sm border-gray-300 rounded-md" data-action="change->kanban#filterByAssignee">
        <option value="">Tous les assignés</option>
        <option value="<%= current_user.id %>">Mes tâches</option>
        <option value="unassigned">Non assignées</option>
      </select>
    </div>
    
    <div class="text-xs text-gray-500">
      <%= widget[:content][:stats][:total] %> tâches • 
      <%= widget[:content][:stats][:overdue] %> en retard • 
      <%= widget[:content][:stats][:completed_this_week] %> terminées cette semaine
    </div>
  </div>
  
  <!-- Kanban Board -->
  <div class="kanban-board flex space-x-4 overflow-x-auto pb-4">
    <% widget[:content][:columns].each do |column| %>
      <div class="kanban-column flex-shrink-0 w-80 bg-gray-50 rounded-lg">
        <!-- Column Header -->
        <div class="px-4 py-3 border-b border-gray-200">
          <div class="flex items-center justify-between">
            <h3 class="font-medium text-gray-900 flex items-center">
              <span class="w-3 h-3 rounded-full bg-<%= column[:color] %>-400 mr-2"></span>
              <%= column[:title] %>
              <span class="ml-2 text-sm text-gray-500">(<%= column[:count] %>)</span>
            </h3>
            <% if column[:actions].present? %>
              <div class="flex space-x-1">
                <% column[:actions].each do |action| %>
                  <button class="p-1 hover:bg-gray-200 rounded" title="<%= action[:label] %>">
                    <%= render UI::IconComponent.new(name: action[:icon], size: :sm) %>
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>
          <% if column[:wip_limit] && column[:count] > column[:wip_limit] %>
            <div class="mt-1 text-xs text-red-600">
              Limite WIP dépassée (<%= column[:wip_limit] %> max)
            </div>
          <% end %>
        </div>
        
        <!-- Tasks Container -->
        <div class="kanban-tasks p-2 space-y-2 min-h-[400px]" data-column="<%= column[:id] %>">
          <% column[:tasks].each do |task| %>
            <div class="kanban-task bg-white rounded-lg shadow-sm p-3 cursor-move hover:shadow-md transition-shadow" 
                 data-task-id="<%= task[:id] %>"
                 draggable="true">
              <!-- Priority indicator -->
              <div class="flex items-start justify-between mb-2">
                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-<%= priority_color(task[:priority]) %>-100 text-<%= priority_color(task[:priority]) %>-800">
                  <%= task[:priority].capitalize %>
                </span>
                <% if task[:blocked] %>
                  <span class="text-red-500" title="<%= task[:blocking_reason] %>">
                    <%= render UI::IconComponent.new(name: 'ban', size: :xs) %>
                  </span>
                <% end %>
              </div>
              
              <!-- Task Title -->
              <h4 class="text-sm font-medium text-gray-900 mb-1"><%= task[:title] %></h4>
              
              <!-- Task Meta -->
              <div class="flex items-center justify-between text-xs text-gray-500">
                <div class="flex items-center space-x-2">
                  <% if task[:due_date] %>
                    <span class="flex items-center <%= 'text-red-600' if task[:overdue] %>">
                      <%= render UI::IconComponent.new(name: 'calendar', size: :xs) %>
                      <%= l(task[:due_date], format: :short) %>
                    </span>
                  <% end %>
                  <span class="text-<%= task[:phase][:color] %>-600">
                    <%= task[:phase][:name] %>
                  </span>
                </div>
                
                <!-- Assignees -->
                <div class="flex -space-x-2">
                  <% task[:assignees].first(3).each do |assignee| %>
                    <%= render UI::UserAvatarComponent.new(
                      user: assignee,
                      size: :xs,
                      class: "ring-2 ring-white"
                    ) %>
                  <% end %>
                  <% if task[:assignees].size > 3 %>
                    <span class="inline-flex items-center justify-center w-6 h-6 rounded-full bg-gray-200 text-xs text-gray-600 ring-2 ring-white">
                      +<%= task[:assignees].size - 3 %>
                    </span>
                  <% end %>
                </div>
              </div>
              
              <!-- Progress bar if in progress -->
              <% if task[:progress] > 0 && column[:id] == 'in_progress' %>
                <div class="mt-2">
                  <%= render UI::ProgressBarComponent.new(
                    percentage: task[:progress],
                    size: :xs
                  ) %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
  </div>
</div>

<style>
.kanban-board {
  min-height: 500px;
}

.kanban-column {
  min-width: 320px;
}

.kanban-task.dragging {
  opacity: 0.5;
}

.kanban-tasks.drag-over {
  background-color: #E5E7EB;
  border: 2px dashed #9CA3AF;
}
</style>
```

### 2.4 API Endpoints pour Dashboard

```ruby
# app/controllers/api/v1/dashboard_controller.rb
module Api
  module V1
    class DashboardController < ApplicationController
      before_action :authenticate_user!
      
      def widgets
        service = DashboardPersonalizationService.new(current_user)
        widgets = service.active_widgets
        
        render json: {
          widgets: widgets,
          available_widgets: current_user.active_profile.available_widgets
        }
      end
      
      def actions
        service = DashboardPersonalizationService.new(current_user)
        actions = service.priority_actions
        
        render json: {
          actions: actions,
          total_count: actions.sum { |a| a[:count] || 0 }
        }
      end
      
      def notifications
        notifications = current_user.notifications
                                   .unread
                                   .order(created_at: :desc)
                                   .limit(10)
        
        render json: {
          notifications: notifications.map { |n| notification_json(n) },
          unread_count: current_user.notifications.unread.count
        }
      end
      
      def metrics
        service = MetricsService.new(current_user, current_user.active_profile)
        metrics = service.dashboard_metrics
        
        render json: { metrics: metrics }
      end
      
      def mark_action_read
        # Marquer une action comme lue/traitée
        action_type = params[:action_type]
        action_id = params[:action_id]
        
        # Logique pour marquer l'action comme traitée
        # Cela dépend du type d'action
        
        render json: { status: 'success' }
      end
      
      private
      
      def notification_json(notification)
        {
          id: notification.id,
          type: notification.notification_type,
          title: notification.title,
          message: notification.message,
          created_at: notification.created_at,
          urgency: notification.urgency,
          actions: notification.actions,
          data: notification.data
        }
      end
    end
  end
end
```

### 2.5 Services Métier Additionnels

#### Service de Métriques

```ruby
# app/services/metrics_service.rb
class MetricsService
  attr_reader :user, :profile
  
  def initialize(user, profile)
    @user = user
    @profile = profile
  end
  
  def dashboard_metrics
    case profile.profile_type
    when 'direction'
      direction_metrics
    when 'chef_projet'
      chef_projet_metrics
    when 'juriste'
      juriste_metrics
    when 'commercial'
      commercial_metrics
    else
      default_metrics
    end
  end
  
  private
  
  def direction_metrics
    [
      {
        title: 'Chiffre d\'affaires',
        value: format_currency(total_revenue),
        change: revenue_change,
        trend: revenue_trend,
        icon: 'currency-euro'
      },
      {
        title: 'Marge globale',
        value: "#{global_margin}%",
        change: margin_change,
        trend: margin_trend,
        icon: 'trending-up'
      },
      {
        title: 'Projets actifs',
        value: active_projects_count,
        change: projects_change,
        trend: 'up',
        icon: 'briefcase'
      },
      {
        title: 'Taux de succès',
        value: "#{success_rate}%",
        change: success_change,
        trend: success_trend,
        icon: 'check-circle'
      }
    ]
  end
  
  def chef_projet_metrics
    [
      {
        title: 'Tâches en cours',
        value: active_tasks_count,
        change: tasks_change,
        trend: tasks_trend,
        icon: 'clipboard-list'
      },
      {
        title: 'Respect délais',
        value: "#{on_time_percentage}%",
        change: on_time_change,
        trend: on_time_trend,
        icon: 'clock'
      },
      {
        title: 'Équipe disponible',
        value: available_team_members,
        change: nil,
        trend: nil,
        icon: 'users'
      },
      {
        title: 'Budget consommé',
        value: "#{budget_consumed}%",
        change: budget_change,
        trend: budget_trend,
        icon: 'credit-card'
      }
    ]
  end
  
  def juriste_metrics
    [
      {
        title: 'Permis actifs',
        value: active_permits_count,
        change: permits_change,
        trend: 'stable',
        icon: 'document-text'
      },
      {
        title: 'Conformité',
        value: "#{compliance_rate}%",
        change: compliance_change,
        trend: compliance_trend,
        icon: 'shield-check'
      },
      {
        title: 'Échéances 30j',
        value: upcoming_deadlines_count,
        change: nil,
        trend: nil,
        icon: 'calendar'
      },
      {
        title: 'Dossiers traités',
        value: processed_files_count,
        change: files_change,
        trend: 'up',
        icon: 'folder-open'
      }
    ]
  end
  
  def commercial_metrics
    [
      {
        title: 'Pipeline',
        value: format_currency(pipeline_value),
        change: pipeline_change,
        trend: pipeline_trend,
        icon: 'chart-bar'
      },
      {
        title: 'Taux conversion',
        value: "#{conversion_rate}%",
        change: conversion_change,
        trend: conversion_trend,
        icon: 'trending-up'
      },
      {
        title: 'Réservations',
        value: reservations_count,
        change: reservations_change,
        trend: 'up',
        icon: 'home'
      },
      {
        title: 'Stock disponible',
        value: available_units_count,
        change: stock_change,
        trend: stock_trend,
        icon: 'cube'
      }
    ]
  end
  
  # Méthodes de calcul (à implémenter selon la logique métier)
  
  def total_revenue
    # Calcul du CA total
    Immo::Promo::Contract.where(organization: user.organization)
                         .where(created_at: current_period)
                         .sum(:amount_cents) / 100
  end
  
  def revenue_change
    # Calcul de l'évolution vs période précédente
    "+12.5%"
  end
  
  def revenue_trend
    'up'
  end
  
  def format_currency(amount)
    number_to_currency(amount, unit: "€", format: "%n %u")
  end
  
  def current_period
    1.month.ago..Time.current
  end
  
  def previous_period
    2.months.ago..1.month.ago
  end
  
  # ... autres méthodes de calcul ...
end
```

#### Service de Navigation

```ruby
# app/services/navigation_service.rb
class NavigationService
  attr_reader :profile
  
  def initialize(profile)
    @profile = profile
  end
  
  def personalized_items
    base_items + profile_specific_items
  end
  
  private
  
  def base_items
    [
      {
        name: 'Tableau de bord',
        path: '/dashboard',
        icon: 'home',
        active: true
      },
      {
        name: 'Documents',
        path: '/ged',
        icon: 'folder',
        badge: pending_documents_count
      },
      {
        name: 'Notifications',
        path: '/notifications',
        icon: 'bell',
        badge: unread_notifications_count
      }
    ]
  end
  
  def profile_specific_items
    case profile.profile_type
    when 'direction'
      [
        {
          name: 'Portfolio',
          path: '/portfolio',
          icon: 'briefcase'
        },
        {
          name: 'Reporting',
          path: '/reports',
          icon: 'chart-bar'
        },
        {
          name: 'Équipes',
          path: '/teams',
          icon: 'users'
        }
      ]
    when 'chef_projet'
      [
        {
          name: 'Projets',
          path: '/immo/promo/projects',
          icon: 'office-building'
        },
        {
          name: 'Planning',
          path: '/planning',
          icon: 'calendar'
        },
        {
          name: 'Ressources',
          path: '/resources',
          icon: 'user-group'
        }
      ]
    when 'juriste'
      [
        {
          name: 'Permis',
          path: '/permits',
          icon: 'clipboard-check'
        },
        {
          name: 'Contrats',
          path: '/contracts',
          icon: 'document-duplicate'
        },
        {
          name: 'Veille',
          path: '/legal-watch',
          icon: 'newspaper'
        }
      ]
    else
      []
    end
  end
  
  def pending_documents_count
    # Logique pour compter les documents en attente
    0
  end
  
  def unread_notifications_count
    profile.user.notifications.unread.count
  end
end
```

### 2.6 Tests d'Intégration

```ruby
# spec/system/dashboard_personalization_spec.rb
require 'rails_helper'

RSpec.describe "Dashboard Personalization", type: :system do
  let(:organization) { create(:organization) }
  
  describe "Direction profile" do
    let(:director) { create(:user, :super_admin, organization: organization) }
    let!(:profile) { create(:user_profile, user: director, profile_type: 'direction') }
    
    before do
      # Créer des données de test
      create_list(:project, 5, :active, organization: organization)
      create_list(:project, 2, :at_risk, organization: organization)
      
      sign_in director
    end
    
    it "displays direction-specific dashboard" do
      visit root_path
      
      # Vérifier le titre personnalisé
      expect(page).to have_content("Bienvenue, #{director.first_name}")
      expect(page).to have_content("Tableau de bord Direction")
      
      # Vérifier les widgets spécifiques
      within('.dashboard-grid') do
        expect(page).to have_css('[data-widget-type="portfolio_overview"]')
        expect(page).to have_css('[data-widget-type="financial_summary"]')
        expect(page).to have_css('[data-widget-type="risk_matrix"]')
      end
      
      # Vérifier les métriques
      expect(page).to have_content("7") # Total projets
      expect(page).to have_content("5") # Projets actifs
      expect(page).to have_content("2") # Projets à risque
    end
    
    it "allows widget customization" do
      visit root_path
      
      # Ouvrir la configuration
      click_button "Configuration"
      
      within('#dashboard-config-modal') do
        # Désactiver un widget
        uncheck "Matrice des risques"
        click_button "Enregistrer"
      end
      
      # Vérifier que le widget est masqué
      expect(page).not_to have_css('[data-widget-type="risk_matrix"]')
    end
  end
  
  describe "Chef de projet profile" do
    let(:chef_projet) { create(:user, :admin, organization: organization) }
    let!(:profile) { create(:user_profile, user: chef_projet, profile_type: 'chef_projet') }
    let!(:project) { create(:project, project_manager: chef_projet, organization: organization) }
    
    before do
      # Créer des tâches
      phase = create(:phase, project: project)
      create_list(:task, 3, :todo, phase: phase, assignees: [chef_projet])
      create_list(:task, 2, :in_progress, phase: phase, assignees: [chef_projet])
      create_list(:task, 1, :overdue, phase: phase, assignees: [chef_projet])
      
      sign_in chef_projet
    end
    
    it "displays chef projet dashboard with kanban" do
      visit root_path
      
      # Vérifier le kanban
      within('.task-kanban-widget') do
        expect(page).to have_content("À faire (3)")
        expect(page).to have_content("En cours (2)")
        expect(page).to have_content("1 en retard")
        
        # Vérifier les cartes de tâches
        expect(page).to have_css('.kanban-task', count: 6)
      end
    end
    
    it "allows drag and drop of tasks" do
      visit root_path
      
      within('.task-kanban-widget') do
        task = find('.kanban-task', match: :first)
        target_column = find('[data-column="in_progress"] .kanban-tasks')
        
        task.drag_to(target_column)
        
        # Vérifier que la tâche a été déplacée
        within('[data-column="in_progress"]') do
          expect(page).to have_css('.kanban-task', count: 3)
        end
      end
    end
  end
  
  describe "Actions panel" do
    let(:user) { create(:user, organization: organization) }
    let!(:profile) { create(:user_profile, user: user) }
    
    before do
      # Créer des actions prioritaires
      create_list(:validation_request, 3, reviewer: user, status: 'pending')
      create_list(:notification, 5, :unread, user: user)
      
      sign_in user
    end
    
    it "displays priority actions" do
      visit root_path
      
      within('.actions-panel') do
        expect(page).to have_content("Actions prioritaires")
        expect(page).to have_content("Validations en attente")
        expect(page).to have_content("3")
        expect(page).to have_content("Notifications non lues")
        expect(page).to have_content("5")
      end
    end
    
    it "allows collapsing actions panel" do
      visit root_path
      
      # Réduire le panneau
      within('.actions-panel') do
        click_button data: { action: 'click->actions-panel#toggle' }
      end
      
      # Vérifier que le panneau est réduit
      expect(page).to have_css('.actions-panel.collapsed')
      
      # Vérifier que le badge total est visible
      expect(page).to have_content("8") # 3 + 5
    end
  end
end
```

## 📊 Phase 3 : Optimisations et Personnalisation

[Cette section sera développée dans la suite du document...]

## 📱 Phase 4 : Intégration Mobile

[Cette section sera développée dans la suite du document...]

## 📈 Métriques et KPIs

### Indicateurs de Performance

1. **Performance Technique**
   - Temps de chargement initial : < 1s
   - Temps de rafraîchissement widget : < 500ms
   - Temps de réponse API : < 200ms P95

2. **Adoption Utilisateur**
   - Taux de personnalisation : > 80% sous 30 jours
   - Nombre moyen de widgets actifs : 4-6
   - Fréquence de visite quotidienne : > 90%

3. **Efficacité Opérationnelle**
   - Réduction du temps de navigation : -50%
   - Réduction des clics pour actions courantes : -60%
   - Augmentation de la productivité : +25%

4. **Satisfaction Utilisateur**
   - Score NPS : > 8/10
   - Taux de rétention : > 95%
   - Feedback positif : > 85%

### Tableau de Bord Analytics

```ruby
# app/services/dashboard_analytics_service.rb
class DashboardAnalyticsService
  def track_widget_interaction(user, widget_type, action)
    DashboardAnalytic.create!(
      user: user,
      widget_type: widget_type,
      action: action,
      timestamp: Time.current,
      session_id: Current.session_id
    )
  end
  
  def usage_report(period = 30.days)
    {
      active_users: active_users_count(period),
      popular_widgets: popular_widgets(period),
      average_session_duration: average_session_duration(period),
      peak_usage_hours: peak_usage_hours(period),
      personalization_rate: personalization_rate
    }
  end
end
```

## 🚀 Conclusion

Cette refonte transforme radicalement l'expérience utilisateur de Docusphere en proposant une interface intelligente et adaptative. Les bénéfices attendus sont :

1. **Productivité accrue** : Réduction drastique du temps nécessaire pour accomplir les tâches quotidiennes
2. **Meilleure adoption** : Interface intuitive adaptée aux besoins spécifiques de chaque profil
3. **Décisions éclairées** : Informations pertinentes présentées au bon moment
4. **Satisfaction utilisateur** : Expérience personnalisée et efficace

Le plan d'implémentation en 4 phases permet une mise en œuvre progressive avec des quick wins dès les premières semaines tout en construisant une base solide pour les évolutions futures.