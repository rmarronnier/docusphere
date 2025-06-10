# 📦 Bibliothèque de Widgets

## 📋 Table des Matières

1. [Types de Widgets](#types-de-widgets)
2. [Widgets par Profil](#widgets-par-profil)
3. [Implémentation Technique](#implémentation-technique)
4. [Tests et Validation](#tests-et-validation)

## 🎯 Types de Widgets

### 📊 Widgets Analytiques

#### Portfolio Overview (2x2)
**Profils :** Direction, Chef Projet
**Description :** Vue consolidée des projets avec KPIs financiers

```ruby
# Configuration
{
  type: 'portfolio_overview',
  config: {
    title: 'Vue Portfolio',
    show_financial_summary: true,
    show_risk_indicators: true,
    projects_limit: 10,
    grouping: 'status' # status, phase, priority
  }
}

# Données retournées
{
  projects: [
    {
      id: 123,
      name: "Résidence Les Jardins",
      status: "in_progress",
      phase: "construction",
      budget: { total: 2500000, spent: 1800000, remaining: 700000 },
      progress: 72,
      risk_level: "medium",
      deadline: "2025-12-15"
    }
  ],
  summary: {
    total_projects: 8,
    total_budget: 15000000,
    total_spent: 9500000,
    avg_progress: 68,
    high_risk_count: 2
  }
}
```

#### Financial Summary (1x1)
**Profils :** Direction, Contrôleur, Chef Projet
**Description :** Résumé financier avec variances

```ruby
# Configuration
{
  type: 'financial_summary',
  config: {
    title: 'Résumé Financier',
    show_variance: true,
    comparison_period: 'month', # month, quarter, year
    currency: 'EUR'
  }
}

# Données retournées
{
  current_period: {
    revenue: 2500000,
    costs: 1800000,
    margin: 700000,
    margin_percentage: 28
  },
  variance: {
    revenue: { amount: 200000, percentage: 8.7, trend: 'up' },
    costs: { amount: -50000, percentage: -2.7, trend: 'down' },
    margin: { amount: 250000, percentage: 55.6, trend: 'up' }
  }
}
```

### 📋 Widgets de Tâches

#### Task Kanban (2x2)
**Profils :** Chef Projet, Juriste
**Description :** Tableau Kanban des tâches par statut

```ruby
# Configuration
{
  type: 'task_kanban',
  config: {
    title: 'Tâches',
    columns: ['todo', 'in_progress', 'review', 'done'],
    show_assignee: true,
    enable_drag_drop: true,
    tasks_per_column: 5
  }
}

# Données retournées
{
  columns: [
    {
      id: 'todo',
      title: 'À faire',
      count: 12,
      tasks: [
        {
          id: 456,
          title: "Valider permis de construire",
          assignee: { name: "Sophie Legrand", avatar: "/avatars/sophie.jpg" },
          priority: "high",
          due_date: "2025-06-15",
          labels: ["urgent", "permis"]
        }
      ]
    }
  ]
}
```

#### Pending Tasks (1x2)
**Profils :** Tous
**Description :** Liste des tâches prioritaires

```ruby
# Configuration
{
  type: 'pending_tasks',
  config: {
    title: 'Tâches en attente',
    limit: 10,
    show_due_date: true,
    urgency_filter: 'all' # all, high, medium
  }
}

# Données retournées
{
  tasks: [
    {
      id: 789,
      title: "Valider document budget Q2",
      type: 'validation',
      urgency: 'high',
      due_date: "2025-06-12",
      assignee: "Marie Dupont",
      link: "/validations/789",
      estimated_time: 30 # minutes
    }
  ],
  total_count: 25,
  urgent_count: 3
}
```

### 📄 Widgets de Contenu

#### Recent Documents (1x2)
**Profils :** Tous
**Description :** Documents récemment modifiés ou consultés

```ruby
# Configuration
{
  type: 'recent_documents',
  config: {
    title: 'Documents récents',
    limit: 8,
    filter_type: 'modified', # modified, viewed, created
    show_thumbnails: true
  }
}

# Données retournées
{
  documents: [
    {
      id: 101,
      name: "Contrat_Fournisseur_ABC.pdf",
      type: "pdf",
      size: "2.4 MB",
      updated_at: "2025-06-10T14:30:00Z",
      updated_by: { name: "Thomas Martin", avatar: "/avatars/thomas.jpg" },
      thumbnail: "/thumbnails/101.jpg",
      tags: ["contrat", "fournisseur"],
      link: "/documents/101"
    }
  ],
  total_count: 156
}
```

#### Document Library (1x2)
**Profils :** Juriste, Architecte
**Description :** Accès rapide à la bibliothèque de documents

```ruby
# Configuration
{
  type: 'document_library',
  config: {
    title: 'Bibliothèque',
    categories: ['contrats', 'plans', 'permis'],
    show_search: true,
    quick_filters: true
  }
}

# Données retournées
{
  categories: [
    {
      name: "Contrats",
      count: 45,
      icon: "document-text",
      link: "/documents?category=contrats"
    },
    {
      name: "Plans",
      count: 128,
      icon: "blueprint",
      link: "/documents?category=plans"
    }
  ],
  quick_actions: [
    { name: "Nouveau document", link: "/documents/new" },
    { name: "Recherche avancée", link: "/search/advanced" }
  ]
}
```

### 🔔 Widgets de Communication

#### Notifications (1x1)
**Profils :** Tous
**Description :** Notifications récentes avec filtres

```ruby
# Configuration
{
  type: 'notifications',
  config: {
    title: 'Notifications',
    limit: 5,
    show_unread_only: false,
    types: ['validation', 'deadline', 'mention']
  }
}

# Données retournées
{
  notifications: [
    {
      id: 234,
      type: 'validation',
      title: "Validation requise",
      message: "Document budget Q2 en attente de validation",
      created_at: "2025-06-10T09:15:00Z",
      read: false,
      urgency: 'high',
      link: "/validations/234",
      sender: { name: "Thomas Martin", avatar: "/avatars/thomas.jpg" }
    }
  ],
  unread_count: 8,
  total_count: 23
}
```

#### Team Communication (1x2)
**Profils :** Chef Projet, Commercial
**Description :** Messages et communications équipe

```ruby
# Configuration
{
  type: 'team_communication',
  config: {
    title: 'Équipe',
    show_recent_messages: true,
    channels: ['general', 'project_alpha'],
    message_limit: 5
  }
}

# Données retournées
{
  channels: [
    {
      id: 'project_alpha',
      name: "Projet Alpha",
      unread_count: 3,
      last_message: {
        text: "Validation plans terminée",
        sender: "Sophie Legrand",
        timestamp: "2025-06-10T16:45:00Z"
      }
    }
  ],
  recent_messages: [
    {
      id: 567,
      channel: "Projet Alpha",
      text: "Réunion chantier reportée à 14h",
      sender: { name: "David Rousseau", avatar: "/avatars/david.jpg" },
      timestamp: "2025-06-10T11:30:00Z"
    }
  ]
}
```

### 📈 Widgets Métier

#### Sales Pipeline (2x2)
**Profils :** Commercial, Direction
**Description :** Pipeline commercial avec entonnoir de ventes

```ruby
# Configuration
{
  type: 'sales_pipeline',
  config: {
    title: 'Pipeline Commercial',
    stages: ['prospect', 'qualified', 'proposal', 'negotiation', 'closed'],
    show_conversion_rates: true,
    period: 'quarter'
  }
}

# Données retournées
{
  stages: [
    {
      name: "Prospects",
      count: 24,
      value: 2400000,
      conversion_rate: 45,
      opportunities: [
        {
          id: 890,
          client: "SCI Les Platanes",
          value: 450000,
          probability: 70,
          close_date: "2025-07-15"
        }
      ]
    }
  ],
  summary: {
    total_value: 8500000,
    weighted_value: 3200000,
    avg_deal_size: 320000,
    close_rate: 32
  }
}
```

#### Legal Calendar (2x1)
**Profils :** Juriste, Direction
**Description :** Calendrier des échéances légales

```ruby
# Configuration
{
  type: 'legal_calendar',
  config: {
    title: 'Échéancier Légal',
    show_upcoming_only: true,
    alert_days: 30,
    categories: ['permis', 'contrats', 'fiscalité']
  }
}

# Données retournées
{
  upcoming_deadlines: [
    {
      id: 345,
      title: "Renouvellement permis construire",
      category: "permis",
      due_date: "2025-07-01",
      days_remaining: 21,
      urgency: 'medium',
      project: "Résidence Les Jardins",
      responsible: "Sophie Legrand",
      link: "/legal/deadlines/345"
    }
  ],
  alerts: [
    {
      type: "overdue",
      count: 2,
      message: "2 échéances dépassées"
    },
    {
      type: "urgent",
      count: 5,
      message: "5 échéances sous 7 jours"
    }
  ]
}
```

## 👥 Widgets par Profil

### Direction Générale
```ruby
DEFAULT_WIDGETS = [
  { type: 'portfolio_overview', size: [2, 2], position: 1 },
  { type: 'financial_summary', size: [1, 1], position: 2 },
  { type: 'risk_matrix', size: [1, 1], position: 3 },
  { type: 'pending_approvals', size: [2, 1], position: 4 },
  { type: 'notifications', size: [1, 1], position: 5 }
]
```

### Chef de Projet
```ruby
DEFAULT_WIDGETS = [
  { type: 'project_timeline', size: [2, 2], position: 1 },
  { type: 'task_kanban', size: [2, 2], position: 2 },
  { type: 'resource_dashboard', size: [2, 1], position: 3 },
  { type: 'team_communication', size: [1, 2], position: 4 },
  { type: 'document_validation', size: [1, 1], position: 5 }
]
```

### Juriste
```ruby
DEFAULT_WIDGETS = [
  { type: 'legal_calendar', size: [2, 1], position: 1 },
  { type: 'document_library', size: [1, 2], position: 2 },
  { type: 'compliance_status', size: [1, 1], position: 3 },
  { type: 'recent_validations', size: [1, 1], position: 4 },
  { type: 'pending_tasks', size: [1, 2], position: 5 }
]
```

### Commercial
```ruby
DEFAULT_WIDGETS = [
  { type: 'sales_pipeline', size: [2, 2], position: 1 },
  { type: 'stock_status', size: [1, 1], position: 2 },
  { type: 'performance_kpis', size: [1, 1], position: 3 },
  { type: 'customer_activity', size: [1, 2], position: 4 },
  { type: 'quick_access', size: [1, 1], position: 5 }
]
```

## ⚙️ Implémentation Technique

### Composant Widget de Base

```ruby
# app/components/dashboard/widget_component.rb
class Dashboard::WidgetComponent < ApplicationComponent
  attr_reader :widget_data, :user, :size, :loading, :error
  
  def initialize(widget_data:, user:, size: nil, loading: false, error: nil)
    @widget_data = widget_data
    @user = user
    @size = size || { width: widget_data[:width] || 1, height: widget_data[:height] || 1 }
    @loading = loading
    @error = error
  end
  
  private
  
  def widget_classes
    classes = [
      'dashboard-widget',
      'bg-white',
      'rounded-lg',
      'shadow',
      'p-4',
      'relative',
      'transition-all',
      'duration-200'
    ]
    
    classes << "col-span-#{size[:width]}" if size[:width] > 1
    classes << "row-span-#{size[:height]}" if size[:height] > 1
    classes << 'animate-pulse' if loading
    classes << 'border-red-300 bg-red-50' if error
    
    classes.join(' ')
  end
  
  def widget_id
    "widget-#{widget_data[:id] || widget_data[:type]}"
  end
  
  def widget_title
    widget_data[:data][:title] || widget_data[:title] || widget_data[:type].humanize
  end
  
  def widget_actions
    widget_data[:data][:actions] || []
  end
  
  def refreshable?
    widget_data[:config][:refreshable] != false
  end
end
```

### Template Widget

```erb
<!-- app/components/dashboard/widget_component.html.erb -->
<div class="<%= widget_classes %>" 
     id="<%= widget_id %>"
     data-widget-id="<%= widget_data[:id] %>"
     data-widget-type="<%= widget_data[:type] %>"
     data-widget-width="<%= size[:width] %>"
     data-widget-height="<%= size[:height] %>">
  
  <% if loading %>
    <%= render partial: 'dashboard/widgets/loading_state' %>
  <% elsif error %>
    <%= render partial: 'dashboard/widgets/error_state', locals: { error: error } %>
  <% else %>
    <!-- Widget Header -->
    <div class="widget-header flex items-center justify-between mb-4">
      <h3 class="widget-title text-lg font-medium text-gray-900">
        <%= widget_title %>
      </h3>
      
      <div class="widget-actions flex items-center space-x-2">
        <% widget_actions.each do |action| %>
          <%= render UI::ButtonComponent.new(
            size: :sm,
            variant: :ghost,
            icon: action[:icon],
            data: { action: action[:type], target: action[:target] }
          ) do %>
            <%= action[:label] %>
          <% end %>
        <% end %>
        
        <% if refreshable? %>
          <button class="text-gray-400 hover:text-gray-600 transition-colors"
                  data-action="click->dashboard#refreshWidget"
                  data-widget-id="<%= widget_data[:id] %>"
                  title="Actualiser">
            <%= render UI::IconComponent.new(name: 'refresh', size: :sm) %>
          </button>
        <% end %>
      </div>
    </div>
    
    <!-- Widget Content -->
    <div class="widget-content">
      <%= render partial: "dashboard/widgets/#{widget_data[:type]}", 
                 locals: { data: widget_data[:data], config: widget_data[:config] } %>
    </div>
    
    <!-- Widget Footer -->
    <% if widget_data[:data][:footer] %>
      <div class="widget-footer mt-4 pt-4 border-t border-gray-200">
        <%= widget_data[:data][:footer] %>
      </div>
    <% end %>
  <% end %>
</div>
```

### Partials Spécialisés

```erb
<!-- app/views/dashboard/widgets/_portfolio_overview.html.erb -->
<div class="portfolio-overview">
  <div class="summary-cards grid grid-cols-2 gap-4 mb-6">
    <div class="summary-card p-3 bg-blue-50 rounded-lg">
      <div class="text-2xl font-bold text-blue-600">
        <%= data[:summary][:total_projects] %>
      </div>
      <div class="text-sm text-blue-800">Projets actifs</div>
    </div>
    
    <div class="summary-card p-3 bg-green-50 rounded-lg">
      <div class="text-2xl font-bold text-green-600">
        <%= number_to_currency(data[:summary][:total_budget], unit: '€', format: '%n %u') %>
      </div>
      <div class="text-sm text-green-800">Budget total</div>
    </div>
  </div>
  
  <div class="projects-list space-y-3">
    <% data[:projects].each do |project| %>
      <div class="project-item p-3 border border-gray-200 rounded-lg hover:bg-gray-50">
        <div class="flex items-center justify-between">
          <div>
            <h4 class="font-medium text-gray-900"><%= project[:name] %></h4>
            <div class="text-sm text-gray-500">
              Phase : <%= project[:phase].humanize %>
            </div>
          </div>
          
          <div class="text-right">
            <div class="text-lg font-semibold text-gray-900">
              <%= project[:progress] %>%
            </div>
            <div class="text-xs text-gray-500">
              <%= project[:status].humanize %>
            </div>
          </div>
        </div>
        
        <div class="mt-2">
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div class="bg-blue-600 h-2 rounded-full" 
                 style="width: <%= project[:progress] %>%"></div>
          </div>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

## 🧪 Tests et Validation

### Tests RSpec

```ruby
# spec/components/dashboard/widget_component_spec.rb
RSpec.describe Dashboard::WidgetComponent, type: :component do
  let(:user) { create(:user) }
  let(:widget_data) do
    {
      id: 1,
      type: 'portfolio_overview',
      width: 2,
      height: 2,
      config: { title: 'Test Widget' },
      data: {
        title: 'Portfolio Overview',
        projects: [],
        summary: { total_projects: 5 }
      }
    }
  end
  
  subject(:component) { described_class.new(widget_data: widget_data, user: user) }
  
  it 'renders widget with correct classes' do
    render_inline(component)
    
    expect(page).to have_css('.dashboard-widget')
    expect(page).to have_css('.col-span-2')
    expect(page).to have_css('.row-span-2')
  end
  
  it 'displays widget title' do
    render_inline(component)
    
    expect(page).to have_content('Portfolio Overview')
  end
  
  it 'includes refresh button when refreshable' do
    render_inline(component)
    
    expect(page).to have_button(title: 'Actualiser')
  end
  
  context 'when loading' do
    subject(:component) { described_class.new(widget_data: widget_data, user: user, loading: true) }
    
    it 'shows loading state' do
      render_inline(component)
      
      expect(page).to have_css('.animate-pulse')
    end
  end
  
  context 'when error' do
    subject(:component) { described_class.new(widget_data: widget_data, user: user, error: 'Test error') }
    
    it 'shows error state' do
      render_inline(component)
      
      expect(page).to have_css('.border-red-300')
    end
  end
end
```

### Tests JavaScript (Vitest)

```javascript
// spec/javascript/controllers/widget_controller_spec.js
import { expect, describe, it, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import WidgetController from '../../../app/javascript/controllers/widget_controller'

describe('WidgetController', () => {
  let application
  let element
  
  beforeEach(() => {
    application = Application.start()
    application.register('widget', WidgetController)
    
    document.body.innerHTML = `
      <div data-controller="widget" 
           data-widget-id="123"
           data-widget-type="portfolio_overview">
        <button data-action="click->widget#refresh">Refresh</button>
        <div data-widget-target="content">
          Original content
        </div>
      </div>
    `
    
    element = document.querySelector('[data-controller="widget"]')
  })
  
  it('refreshes widget content', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({
        status: 'success',
        widget: { content: 'Updated content' }
      })
    })
    
    const controller = application.getControllerForElementAndIdentifier(element, 'widget')
    const refreshButton = element.querySelector('button')
    
    refreshButton.click()
    
    // Wait for async operation
    await new Promise(resolve => setTimeout(resolve, 0))
    
    expect(fetch).toHaveBeenCalledWith('/dashboard/widgets/123/refresh', {
      method: 'POST',
      headers: expect.objectContaining({
        'Accept': 'application/json'
      })
    })
  })
})
```

---

**Navigation :** [← Dashboard System](./03_DASHBOARD_SYSTEM.md) | [Implementation Phases →](./05_IMPLEMENTATION_PHASES.md)