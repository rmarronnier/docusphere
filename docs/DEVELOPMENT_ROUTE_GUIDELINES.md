# 🛣️ Consignes de Développement - Routes & Chemins

## 🚨 Règles Obligatoires

### 1. **JAMAIS de chemins hardcodés**
```erb
<!-- ❌ INTERDIT -->
<%= link_to "Document", "/ged/documents/1" %>
<%= link_to "Projects", "/immo/promo/projects" %>
<%= image_tag "/icons/logo.png" %>

<!-- ✅ OBLIGATOIRE -->
<%= link_to "Document", ged_document_path(document) %>
<%= link_to "Projects", immo_promo_engine.projects_path %>
<%= image_tag asset_path("icons/logo.png") %>
```

### 2. **ViewComponents : toujours `helpers.xxx_path`**
```erb
<!-- ❌ INTERDIT dans app/components/**/*.erb -->
<%= link_to "Dashboard", dashboard_path %>
<%= form_with url: search_path %>

<!-- ✅ OBLIGATOIRE dans ViewComponents -->
<%= link_to "Dashboard", helpers.dashboard_path %>
<%= form_with url: helpers.search_path %>
```

### 3. **Engines : utiliser les helpers appropriés**
```ruby
# Dans l'app principale vers l'engine
immo_promo_engine.projects_path

# Dans l'engine vers l'app principale  
main_app.ged_dashboard_path

# Dans l'engine vers l'engine même
projects_path
```

## 🔧 Outils d'Automatisation Installés

### Validation Automatique Activée

#### 1. **GitHub Actions** 
- ✅ Validation automatique sur chaque PR/push
- ✅ Génération de rapports d'erreurs
- ✅ Workflow : `.github/workflows/route-validation.yml`

#### 2. **Rake Tasks Disponibles**
```bash
# Audit complet des routes
rake routes:audit

# Correction automatique problèmes ViewComponent  
rake routes:fix_common_issues

# Setup environnement dev avec validation
rake dev:setup

# Validation complète (audit + tests)
rake dev:validate_routes

# Correction de tous les problèmes auto-corrigeables
rake dev:fix_routes
```

#### 3. **Scripts de Développement**
```bash
# Validation manuelle avant commit
./bin/pre-commit

# Installation hooks Git (optionnel)
./bin/setup-git-hooks
```

## 📋 Workflow de Développement

### Avant chaque commit :
```bash
# 1. Auto-fix des problèmes ViewComponent
rake routes:fix_common_issues

# 2. Validation complète
rake routes:audit

# 3. Si erreurs : corriger manuellement
# 4. Valider avec tests
rake dev:validate_routes
```

### Avant chaque PR :
- ✅ GitHub Actions valide automatiquement
- ✅ Aucune erreur de route autorisée
- ✅ Tests système de navigation passants

## 📊 Types d'Erreurs Détectées

### 1. **Routes Manquantes** 
- Helper utilisé mais route inexistante
- **Action** : Ajouter route ou corriger référence

### 2. **Chemins Hardcodés**
- URLs en dur au lieu d'helpers
- **Action** : Remplacer par helpers appropriés

### 3. **ViewComponent Mal Configurés**
- Route helpers sans `helpers.` prefix
- **Action** : Auto-corrigé par `rake routes:fix_common_issues`

### 4. **Engines Mal Référencés**
- Chemins engine hardcodés
- **Action** : Utiliser `xxx_engine.route_path`

## 🎯 Standards Appliqués

### Nomenclature Routes
- **GED** : Préfixe `ged_*` pour toutes les routes documentaires
- **API** : Scope `/api` avec préfixe `api_*`
- **Engine** : Helpers `engine_name.route_path`
- **Assets** : `asset_path()` pour tous les fichiers statiques

### Architecture Routes
```ruby
# config/routes.rb structure recommandée
Rails.application.routes.draw do
  root "home#index"
  
  # Core features avec namespace
  scope '/ged', as: 'ged' do
    # Routes GED
  end
  
  # API avec scope
  scope '/api', as: 'api' do
    # Routes API
  end
  
  # Engines montés
  mount EngineName::Engine => "/engine/path"
end
```

## ⚠️ Erreurs Courantes Évitées

### 1. **Links brisés en production**
- URLs hardcodées qui changent
- **Solution** : Route helpers dynamiques

### 2. **Erreurs ViewComponent**
- Context d'exécution différent
- **Solution** : `helpers.route_path` systématique

### 3. **Refactoring cassant**
- Changement routes → liens brisés
- **Solution** : Helpers mise à jour automatique

### 4. **Tests flaky**
- Navigation incohérente
- **Solution** : Tests système automatisés

## 🚀 Fonctionnalités Automatisées

### Auto-Fix Activé
- ✅ **ViewComponent route helpers** : Ajout automatique `helpers.`
- ✅ **Detection chemins hardcodés** : Warnings avec suggestions
- ✅ **Validation routes** : Test existence avant utilisation

### CI/CD Intégré
- ✅ **Validation automatique** sur chaque commit
- ✅ **Rapports d'erreurs** générés automatiquement
- ✅ **Blocage merge** si erreurs critiques

### Tests Continus
- ✅ **Navigation fonctionnelle** testée automatiquement
- ✅ **Links brisés** détectés immédiatement
- ✅ **Performance routing** monitored

## 💡 Aide Rapide

### Commandes de Debugging
```bash
# Voir toutes les routes
rails routes

# Routes d'un engine spécifique
rails routes | grep immo_promo

# Test helper en console
rails c
> ged_document_path(1)

# Audit rapide
rake routes:audit
```

### Où Chercher en Cas d'Erreur
1. **Route manquante** → `config/routes.rb`
2. **ViewComponent** → Ajouter `helpers.`
3. **Engine** → Vérifier mount point
4. **Asset** → Utiliser `asset_path()`

---

**⚡ Ces outils garantissent 0 erreur de route en production !**

Suivre ces consignes = Navigation fluide et application stable 🎉