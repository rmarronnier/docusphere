# 🏗️ Architecture de l'Interface

## 📋 Table des Matières

1. [Structure Globale](#structure-globale)
2. [Composants Clés](#composants-clés)
3. [Design System](#design-system)
4. [Architecture Technique](#architecture-technique)
5. [Responsive Design](#responsive-design)

## 🎯 Structure Globale

### Layout Principal

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

### Zones Fonctionnelles

1. **Header (Navbar)** - Navigation globale et recherche
2. **Sidebar (Actions Panel)** - Actions prioritaires et raccourcis
3. **Main Content** - Grille de widgets personnalisables
4. **Secondary Content** - Zone optionnelle pour contenu contextuel

## 🧩 Composants Clés

### 1. Navbar Adaptative

**Fonctionnalités :**
- Logo et nom de l'organisation
- Navigation principale contextuelle selon profil
- Barre de recherche intelligente avec suggestions
- Centre de notifications avec filtres
- Menu utilisateur avec accès rapide

**Responsive :**
- Desktop : Navigation horizontale complète
- Tablet : Menu hamburger pour navigation secondaire
- Mobile : Interface collapsed avec drawer

**Code Structure :**
```erb
<nav class="navbar" data-controller="navbar">
  <div class="navbar-brand">
    <%= render UI::IconComponent.new(name: 'logo') %>
    <span class="organization-name"><%= current_organization.name %></span>
  </div>
  
  <div class="navbar-nav" data-navbar-target="navigation">
    <%= render Navigation::NavbarComponent.new(
      user: current_user,
      profile: current_user.active_profile
    ) %>
  </div>
  
  <div class="navbar-actions">
    <%= render Forms::SearchFormComponent.new(
      placeholder: t('search.global_placeholder'),
      data: { controller: 'search-autocomplete' }
    ) %>
    
    <%= render Notifications::NotificationDropdownComponent.new(
      user: current_user
    ) %>
    
    <%= render ProfileSwitcherComponent.new(user: current_user) %>
  </div>
</nav>
```

### 2. Actions Panel (Sidebar)

**Fonctionnalités :**
- Actions prioritaires triées par urgence
- Compteurs visuels avec badges
- Accès rapide aux favoris
- Zone personnalisable par profil
- État collapsible

**Code Structure :**
```erb
<aside class="actions-panel" data-controller="actions-panel">
  <div class="panel-header">
    <h2>Actions prioritaires</h2>
    <button data-action="click->actions-panel#toggle">
      <%= render UI::IconComponent.new(name: 'chevron-left') %>
    </button>
  </div>
  
  <div class="panel-content">
    <%= render Dashboard::ActionsPanelComponent.new(
      actions: @dashboard_data[:actions],
      user: current_user
    ) %>
  </div>
</aside>
```

### 3. Zone Principale (Dashboard Grid)

**Fonctionnalités :**
- Grille CSS adaptative (1-4 colonnes)
- Widgets redimensionnables
- Drag & drop pour réorganisation
- États de chargement et d'erreur

**Code Structure :**
```erb
<main class="dashboard-main">
  <div class="dashboard-widgets" 
       data-controller="dashboard-sortable"
       data-dashboard-sortable-target="container">
    <% @dashboard_data[:widgets].each do |widget_data| %>
      <div class="dashboard-widget" 
           data-widget-id="<%= widget_data[:id] %>"
           data-controller="widget-resize">
        <%= render Dashboard::WidgetComponent.new(
          widget_data: widget_data,
          user: current_user
        ) %>
      </div>
    <% end %>
  </div>
</main>
```

### 4. Widgets Modulaires

**Structure Standard :**
- Header avec titre et actions
- Corps avec contenu spécifique
- Footer optionnel avec liens
- États : normal, loading, error, empty

**Code Structure :**
```erb
<div class="widget" data-widget-type="<%= widget_type %>">
  <header class="widget-header">
    <h3><%= title %></h3>
    <div class="widget-actions">
      <button data-action="refresh">
        <%= render UI::IconComponent.new(name: 'refresh') %>
      </button>
    </div>
  </header>
  
  <div class="widget-content">
    <%= content %>
  </div>
  
  <footer class="widget-footer" if="<%= footer.present? %>">
    <%= footer %>
  </footer>
</div>
```

## 🎨 Design System

### Palette de Couleurs

```css
:root {
  /* Couleurs principales */
  --primary-50: #eff6ff;
  --primary-500: #3b82f6;
  --primary-600: #2563eb;
  --primary-700: #1d4ed8;
  
  /* Couleurs sémantiques */
  --success: #10b981;
  --warning: #f59e0b;
  --error: #ef4444;
  --info: #3b82f6;
  
  /* Couleurs neutres */
  --gray-50: #f9fafb;
  --gray-100: #f3f4f6;
  --gray-200: #e5e7eb;
  --gray-500: #6b7280;
  --gray-900: #111827;
}
```

### Typographie

```css
:root {
  /* Font families */
  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  
  /* Font sizes */
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  
  /* Line heights */
  --leading-tight: 1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;
}
```

### Espacements

```css
:root {
  /* Spacing scale */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;
}
```

### Ombres et Effets

```css
:root {
  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  
  /* Border radius */
  --radius-sm: 0.125rem;
  --radius: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-full: 9999px;
  
  /* Transitions */
  --transition-fast: 150ms ease;
  --transition-normal: 300ms ease;
  --transition-slow: 500ms ease;
}
```

## ⚙️ Architecture Technique

### Stack Frontend

```yaml
Runtime: Bun (JavaScript runtime)
Framework: Rails 7.1 + Stimulus
Styling: TailwindCSS + Custom CSS
Components: ViewComponent
Build: Bun build pipeline
Testing: RSpec + Vitest (JavaScript)
```

### Structure des Composants

```
app/components/
├── application_component.rb         # Base component
├── ui/                             # UI primitives
│   ├── button_component.rb
│   ├── card_component.rb
│   ├── modal_component.rb
│   └── data_grid_component/        # Modular component
│       ├── column_component.rb
│       ├── cell_component.rb
│       └── header_cell_component.rb
├── dashboard/                      # Dashboard-specific
│   ├── widget_component.rb
│   ├── actions_panel_component.rb
│   └── statistics_widget.rb
├── navigation/                     # Navigation components
│   ├── navbar_component.rb
│   └── breadcrumb_component.rb
└── forms/                         # Form components
    ├── field_component.rb
    └── search_form_component.rb
```

### Controllers JavaScript

```
app/javascript/controllers/
├── application.js                  # Base controller
├── dashboard_controller.js         # Dashboard coordination
├── dashboard_sortable_controller.js # Drag & drop
├── widget_resize_controller.js     # Widget resizing
├── search_autocomplete_controller.js
└── mobile_menu_controller.js
```

### Services Architecture

```
app/services/
├── dashboard_personalization_service.rb  # Dashboard logic
├── widget_cache_service.rb               # Widget caching
├── navigation_service.rb                 # Navigation logic
├── metrics_service.rb                    # Metrics calculation
└── default_widget_service.rb             # Default widgets
```

## 📱 Responsive Design

### Breakpoints

```css
/* Mobile first approach */
@media (min-width: 640px)  { /* sm */ }
@media (min-width: 768px)  { /* md */ }
@media (min-width: 1024px) { /* lg */ }
@media (min-width: 1280px) { /* xl */ }
@media (min-width: 1536px) { /* 2xl */ }
```

### Grid Adaptation

```css
.dashboard-widgets {
  display: grid;
  gap: 1rem;
  
  /* Mobile: 1 column */
  grid-template-columns: 1fr;
  
  /* Tablet: 2 columns */
  @media (min-width: 768px) {
    grid-template-columns: repeat(2, 1fr);
  }
  
  /* Desktop: 3 columns */
  @media (min-width: 1024px) {
    grid-template-columns: repeat(3, 1fr);
  }
  
  /* Large desktop: 4 columns */
  @media (min-width: 1280px) {
    grid-template-columns: repeat(4, 1fr);
  }
}
```

### Navigation Mobile

```css
.navbar {
  /* Desktop navigation */
  .navbar-nav {
    display: flex;
  }
  
  /* Mobile navigation */
  @media (max-width: 767px) {
    .navbar-nav {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      background: white;
      z-index: 1000;
    }
    
    .navbar-nav.open {
      display: flex;
      flex-direction: column;
    }
  }
}
```

### Widgets Responsifs

```css
.dashboard-widget {
  /* Base styles */
  position: relative;
  background: white;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow);
  
  /* Mobile adjustments */
  @media (max-width: 767px) {
    /* Force single column */
    grid-column: 1 !important;
    
    /* Adjust padding */
    .widget-content {
      padding: var(--space-3);
    }
    
    /* Stack widget actions */
    .widget-header {
      flex-direction: column;
      gap: var(--space-2);
    }
  }
}
```

## 🎯 Patterns d'Interaction

### Drag & Drop

1. **Mode Edition** : Bouton toggle pour activer/désactiver
2. **Handles visuels** : Apparition au survol en mode édition
3. **Feedback visuel** : Ghost, placeholder, animations
4. **Sauvegarde auto** : Persistance immédiate des changements

### Notifications

1. **Toast système** : Notifications temporaires (succès, erreur)
2. **Badges compteurs** : Indicateurs numériques sur navigation
3. **Panneau notifications** : Dropdown avec historique
4. **Alertes contextuelles** : Intégrées dans les widgets

### États de Chargement

1. **Skeleton loading** : Placeholder pendant chargement
2. **Shimmer effect** : Animation de chargement fluide
3. **Progressive enhancement** : Affichage par étapes
4. **Error boundaries** : Gestion d'erreurs gracieuse

---

**Navigation :** [← Profils Utilisateurs](./01_USER_PROFILES.md) | [Dashboard System →](./03_DASHBOARD_SYSTEM.md)