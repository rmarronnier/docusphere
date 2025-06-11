# 🛣️ Guide des Patterns de Routes - DocuSphere

## 🎯 Problème Identifié

Les erreurs de chemins dans l'application sont courantes et causent des liens brisés, erreurs 404, et mauvaise expérience utilisateur. Voici un guide complet pour les éviter.

## 🔍 Types d'Erreurs de Chemins Identifiées

### 1. **Helpers de routes inexistants** ❌

```erb
<!-- ERREUR -->
<%= link_to "Modifier", edit_document_path(document) %>
<!-- Cette route n'existe pas -->

<!-- CORRECT -->
<%= link_to "Voir", ged_document_path(document) %>
<!-- Utilise la route réellement définie -->
```

### 2. **Inconsistance dans les ViewComponents** ❌

```erb
<!-- ERREUR dans app/components/xxx_component.html.erb -->
<%= link_to "Dashboard", dashboard_path %>
<!-- Peut ne pas fonctionner dans le contexte du composant -->

<!-- CORRECT -->
<%= link_to "Dashboard", helpers.dashboard_path %>
<!-- Utilise explicitement le helper -->
```

### 3. **Chemins hardcodés vers les engines** ❌

```erb
<!-- ERREUR -->
<%= link_to "Projets", "/immo/promo/projects" %>
<!-- Cassé si l'engine change de mount point -->

<!-- CORRECT -->
<%= link_to "Projets", immo_promo_engine.projects_path %>
<!-- Utilise le helper d'engine -->
```

### 4. **Rescue silencieux masquant les erreurs** ❌

```erb
<!-- PROBLÉMATIQUE -->
data-url="<%= some_path rescue '/fallback' %>"
<!-- Masque les erreurs de routes -->

<!-- CORRECT -->
<% if respond_to?(:some_path) %>
  data-url="<%= some_path %>"
<% else %>
  data-url="/fallback"
<% end %>
<!-- Gestion explicite des erreurs -->
```

## ✅ Patterns Recommandés

### 1. **Validation des Routes avec Tests**

```ruby
# spec/routing/route_helpers_spec.rb
RSpec.describe "Route Helpers", type: :routing do
  it "validates essential routes exist" do
    expect(Rails.application.routes.url_helpers).to respond_to(:ged_document_path)
    expect(Rails.application.routes.url_helpers).to respond_to(:dashboard_path)
  end
end
```

### 2. **Usage Correct dans ViewComponents**

```erb
<!-- app/components/document_card_component.html.erb -->
<%= link_to document.title, helpers.ged_document_path(document) %>
<%= link_to "Télécharger", helpers.ged_download_document_path(document) %>

<!-- Pour les data attributes -->
<div data-controller="document-actions"
     data-document-actions-download-url-value="<%= helpers.ged_download_document_path(document) %>">
```

### 3. **Helpers d'Engine Corrects**

```ruby
# Dans le code Ruby (contrôleurs, modèles)
immo_promo_engine.projects_path

# Dans les vues de l'application principale
<%= link_to "Projets ImmoPromo", immo_promo_engine.projects_path %>

# Dans les vues de l'engine lui-même
<%= link_to "Projets", projects_path %>
<%= link_to "Retour app", main_app.ged_dashboard_path %>
```

### 4. **Gestion Défensive des Routes**

```erb
<!-- Vérification d'existence -->
<% if respond_to?(:optional_route_path) %>
  <%= link_to "Lien optionnel", optional_route_path %>
<% end %>

<!-- Avec fallback explicite -->
<%
  document_url = begin
                   ged_document_path(document)
                 rescue ActionController::UrlGenerationError
                   "#"
                 end
%>
<%= link_to "Document", document_url %>
```

## 🔧 Outils de Détection et Prévention

### 1. **Rake Task d'Audit**

```bash
# Auditer toutes les routes dans l'application
rake routes:audit

# Corriger automatiquement les problèmes courants
rake routes:fix_common_issues

# Générer des tests de validation
rake routes:generate_validation_test
```

### 2. **Tests Automatisés**

```ruby
# Test toutes les pages principales pour liens brisés
# spec/system/navigation_paths_spec.rb
RSpec.describe "Navigation Paths", type: :system do
  it "validates main navigation works" do
    visit root_path
    all("a[href^='/']").each do |link|
      visit link[:href]
      expect(page).to have_http_status(:ok)
    end
  end
end
```

### 3. **Linter Personnalisé**

```ruby
# .rubocop_custom.yml
Rails/RouteHelper:
  Description: 'Use route helpers instead of hardcoded paths'
  Enabled: true
  Include:
    - 'app/views/**/*.erb'
    - 'app/components/**/*.erb'
```

## 📋 Checklist de Validation

### Avant de déployer :

- [ ] `rake routes:audit` sans erreurs
- [ ] Tests système passent sans liens brisés
- [ ] Pas de chemins hardcodés dans les vues
- [ ] ViewComponents utilisent `helpers.xxx_path`
- [ ] Routes d'engines utilisent les helpers appropriés

### Pour chaque nouvelle route :

- [ ] Route ajoutée dans `config/routes.rb`
- [ ] Helper testé dans `rails console`
- [ ] Test de route créé dans `spec/routing/`
- [ ] Utilisation documentée si complexe

### Pour chaque nouveau component :

- [ ] Utilise `helpers.xxx_path` pour les routes
- [ ] Teste le rendu avec ViewComponent
- [ ] Vérifie les data attributes avec routes

## 🛠️ Commands Utiles

```bash
# Voir toutes les routes disponibles
rails routes

# Voir les routes d'un engine spécifique
rails routes | grep immo_promo

# Tester un helper en console
rails console
> Rails.application.routes.url_helpers.ged_document_path(1)

# Lancer l'audit complet
rake routes:audit

# Tests spécifiques aux routes
bundle exec rspec spec/routing/
bundle exec rspec spec/system/navigation_paths_spec.rb
```

## 🎯 Architecture de Routes Recommandée

### Structure des Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Core application
  root "home#index"
  resource :dashboard, only: [:show]
  
  # Namespace par fonctionnalité
  scope '/ged', as: 'ged' do
    get '/', to: 'ged#dashboard', as: 'dashboard'
    get '/documents/:id', to: 'ged#show_document', as: 'document'
    # ...
  end
  
  # Engines montés
  mount ImmoPromo::Engine => "/immo/promo"
end
```

### Nomenclature Cohérente

- **Prefixes cohérents** : `ged_*` pour GED, `admin_*` pour admin
- **Verbes standards** : `show`, `edit`, `create`, `update`, `destroy`
- **Noms descriptifs** : `download_document` pas juste `download`

## 🚨 Erreurs à Éviter Absolument

1. **Ne jamais hardcoder les URLs** : `/immo/promo/projects` → `immo_promo_engine.projects_path`
2. **Ne pas ignorer les erreurs de routes** : `rescue` silencieux
3. **Ne pas mélanger les contextes** : `xxx_path` direct dans ViewComponents
4. **Ne pas oublier les engines** : Routes différentes selon le contexte
5. **Ne pas tester uniquement manuellement** : Automatiser la validation

## 🎉 Résultat Attendu

Avec ces patterns appliqués :
- ✅ **0 lien brisé** en production
- ✅ **Navigation fluide** pour les utilisateurs  
- ✅ **Maintenabilité** accrue du code
- ✅ **Refactoring sûr** des routes
- ✅ **Tests automatisés** détectant les régressions

---

**Règle d'or** : Toujours utiliser les helpers de routes Rails au lieu de chemins hardcodés !