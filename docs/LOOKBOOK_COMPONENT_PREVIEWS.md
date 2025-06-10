# Guide des Previews de Composants Lookbook

## État Actuel - Résumé

### ✅ Composants avec Previews Fonctionnels

| Composant | Scenarios | Status | Notes |
|-----------|-----------|--------|-------|
| **Alert** | 7 | ✅ Fonctionnel | Types, dismissible, actions |
| **Button** | 9 | ✅ Fonctionnel | Variants, tailles, états |
| **Card** | 5 | ✅ Fonctionnel | Avec/sans footer, variations |
| **DataGrid** | 12 | ✅ Fonctionnel | Actions, formatage, états vides |
| **EmptyState** | 9 | ✅ Fonctionnel | Icônes, messages, actions |
| **Modal** | 6 | ✅ Fonctionnel | Tailles, footer, formulaires |

### 🚧 Composants Créés (À Vérifier)

| Composant | Scenarios | Status | Issues |
|-----------|-----------|--------|--------|
| **StatusBadge** | 3 | ⚠️ Erreur 500 | Paramètres incompatibles |
| **Icon** | 4 | ❓ Non testé | - |
| **ProgressBar** | 4 | ❓ Non testé | - |
| **UserAvatar** | 5 | ❓ Non testé | - |
| **StatCard** | 4 | ❓ Non testé | - |
| **Dropdown** | 5 | ❓ Non testé | - |
| **Notification** | 5 | ❓ Non testé | - |
| **Forms::Field** | 5 | ❓ Non testé | - |
| **Forms::SearchForm** | 6 | ❓ Non testé | - |
| **Navigation::Breadcrumb** | 6 | ❓ Non testé | - |
| **Documents::DocumentCard** | 5 | ❓ Non testé | - |

## Composants Créés Aujourd'hui

### 1. Status Badge Component ⚠️
**Fichier:** `/test/components/previews/ui/status_badge_component_preview.rb`
**Problème:** Erreur 500 lors de l'accès
**Solution:** Vérifier les paramètres du composant

### 2. Icon Component 
**Fichier:** `/test/components/previews/ui/icon_component_preview.rb`
**Scenarios:** default, sizes, common_icons, icon_colors

### 3. Progress Bar Component
**Fichier:** `/test/components/previews/ui/progress_bar_component_preview.rb`
**Scenarios:** default, progress_values, sizes, with_labels

### 4. User Avatar Component
**Fichier:** `/test/components/previews/ui/user_avatar_component_preview.rb`
**Scenarios:** default, with_image, sizes, multiple_users, avatar_group

### 5. Stat Card Component
**Fichier:** `/test/components/previews/ui/stat_card_component_preview.rb`
**Scenarios:** default, multiple_stats, with_trends, variants

### 6. Dropdown Component
**Fichier:** `/test/components/previews/ui/dropdown_component_preview.rb`
**Scenarios:** default, variants, with_icons_and_dividers, sizes, positions

### 7. Notification Component
**Fichier:** `/test/components/previews/ui/notification_component_preview.rb`
**Scenarios:** default, all_types, with_actions, dismissible, compact

### 8. Form Field Component
**Fichier:** `/test/components/previews/forms/field_component_preview.rb`
**Scenarios:** default, field_types, field_states, with_icons_and_help, field_sizes

### 9. Search Form Component
**Fichier:** `/test/components/previews/forms/search_form_component_preview.rb`
**Scenarios:** default, with_filters, compact, with_suggestions, advanced, sizes

### 10. Breadcrumb Component
**Fichier:** `/test/components/previews/navigation/breadcrumb_component_preview.rb`
**Scenarios:** default, simple, deep_navigation, with_icons, compact, different_separators

### 11. Document Card Component
**Fichier:** `/test/components/previews/documents/document_card_component_preview.rb`
**Scenarios:** default, different_types, document_states, with_actions, compact

## Prochaines Étapes

### 1. Validation et Correction
- [ ] Tester chaque nouveau preview individuellement
- [ ] Corriger les erreurs de paramètres
- [ ] Vérifier que tous les composants existent

### 2. Optimisation des Previews
- [ ] Simplifier les previews complexes
- [ ] Utiliser des données factices réalistes
- [ ] Ajouter des annotations explicatives

### 3. Capture Complète
- [ ] Mettre à jour le script de capture
- [ ] Générer tous les screenshots
- [ ] Organiser la documentation visuelle

## Commandes Utiles

### Lister tous les previews
```bash
docker-compose run --rm web rails runner '
Lookbook.previews.each do |preview|
  puts "#{preview.name} (#{preview.scenarios.count} scenarios)"
end
'
```

### Tester un preview spécifique
```bash
docker-compose run --rm web curl -s -I http://web:3000/rails/lookbook/preview/[path]
```

### Capturer tous les screenshots
```bash
docker-compose run --rm web rake lookbook:capture
```

## Architecture des Previews

### Convention de Nommage
- **UI Components:** `ui/[component_name]_component_preview.rb`
- **Form Components:** `forms/[component_name]_component_preview.rb`
- **Navigation:** `navigation/[component_name]_component_preview.rb`
- **Documents:** `documents/[component_name]_component_preview.rb`

### Structure Type
```ruby
# @label Component Name
class Namespace::ComponentNamePreview < Lookbook::Preview
  layout "application"
  
  # @label Default Example
  def default
    render ComponentName.new(param: value)
  end
  
  # @label Variations
  def variations
    # Multiple examples
  end
end
```

### Bonnes Pratiques
1. **Simplicité:** Commencer par des exemples simples
2. **Progression:** Aller du simple au complexe
3. **Données réalistes:** Utiliser des données qui font sens
4. **Documentation:** Ajouter des labels explicites
5. **Groupement:** Organiser les scenarios par thème

## Statistiques

- **Total composants:** 17
- **Total scenarios:** 105+
- **Composants fonctionnels:** 6
- **Composants créés aujourd'hui:** 11
- **Taux de couverture:** ~40% des composants de l'app