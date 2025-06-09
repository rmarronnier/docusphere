# Guide Complet pour Corriger les Tests des Modèles

## Vue d'ensemble

Ce document fournit une analyse exhaustive des échecs de tests dans les modèles et concerns, avec des solutions concrètes pour chaque type de problème. L'analyse a révélé **406 échecs sur 1111 tests**, principalement dus à des problèmes de configuration plutôt qu'à des bugs de code.

## 🔍 Analyse des Patterns d'Erreurs

### 1. **Concerns mal configurés (≈40% des échecs)**

#### A. WorkflowManageable Concern
**Problème**: Le modèle `Workflow` n'inclut pas le concern `WorkflowManageable`
**Impact**: ~20 tests échouent
**Solution**:
```ruby
# app/models/workflow.rb
class Workflow < ApplicationRecord
  include WorkflowManageable  # AJOUTER CETTE LIGNE
  # ... reste du code
end
```

#### B. Addressable Concern  
**Problème**: Les tests utilisent une table 'projects' qui n'existe pas
**Impact**: 4 tests échouent
**Solution**:
```ruby
# spec/models/concerns/addressable_spec.rb
# Remplacer:
self.table_name = 'projects'
# Par:
self.table_name = 'immo_promo_projects'
```

#### C. Authorizable Concern
**Problème**: Les tests ne sauvegardent pas les instances avant de tester les autorisations
**Solution**: Ajouter `.save!` avant les tests d'autorisation

### 2. **Factories manquantes ou mal nommées (≈30% des échecs)**

#### Factories à créer/corriger:
```ruby
# spec/factories/workflow_steps.rb
FactoryBot.define do
  factory :workflow_step do
    workflow
    name { "Step #{sequence(:n)}" }
    position { sequence(:n) }
    status { 'pending' }
  end
end

# spec/factories/immo/promo/lot_specifications.rb
FactoryBot.define do
  factory :immo_promo_lot_specification, class: 'Immo::Promo::LotSpecification' do
    lot { association :immo_promo_lot }
    name { "Spec #{sequence(:n)}" }
    specification_type { 'room_count' }  # IMPORTANT: définir l'enum
    value { "3" }
  end
end
```

**Attention aux conventions de nommage**:
- Factory: `immo_promo_contract`
- Classe: `Immo::Promo::Contract`
- Table: `immo_promo_contracts`

### 3. **Enums non déclarés (≈15% des échecs)**

#### Modèles nécessitant des enums:
```ruby
# engines/immo_promo/app/models/immo/promo/lot_specification.rb
class LotSpecification < ApplicationRecord
  # AJOUTER:
  enum specification_type: {
    room_count: 'room_count',
    surface_area: 'surface_area',
    floor: 'floor',
    orientation: 'orientation',
    parking: 'parking',
    terrace: 'terrace',
    garden: 'garden',
    storage: 'storage'
  }
end

# engines/immo_promo/app/models/immo/promo/certification.rb
class Certification < ApplicationRecord
  # AJOUTER:
  enum certification_type: {
    quality: 'quality',
    environmental: 'environmental',
    safety: 'safety',
    technical: 'technical'
  }
  
  enum status: {
    valid: 'valid',
    expired: 'expired',
    pending_renewal: 'pending_renewal'
  }
end
```

### 4. **Méthodes métier manquantes (≈10% des échecs)**

#### Méthodes à implémenter:
```ruby
# app/models/document.rb
def can_be_edited_by?(user)
  return false if locked?
  uploaded_by == user || user.admin?
end

def can_be_deleted_by?(user)
  uploaded_by == user || user.admin?
end

# engines/immo_promo/app/models/immo/promo/time_log.rb
def billable_hours
  return 0 unless billable?
  hours_worked
end

def total_cost
  return 0 unless hourly_rate && hours_worked
  hourly_rate * hours_worked
end
```

### 5. **Associations incorrectes (≈5% des échecs)**

#### Corrections nécessaires:
```ruby
# engines/immo_promo/app/models/immo/promo/progress_report.rb
class ProgressReport < ApplicationRecord
  belongs_to :author, class_name: 'User'  # Pas seulement :user
  belongs_to :project, optional: true     # AJOUTER
  belongs_to :phase, optional: true       # AJOUTER
end
```

## 🎯 Découvertes Importantes

### 1. **Schema vs Modèles**
- La table `documents` a TOUTES les colonnes nécessaires (AI fields, documentable, storage_path, etc.)
- La table `workflow_submissions` a été correctement mise à jour avec priority, submittable, etc.
- Les tables `immo_promo_*` existent toutes avec les bonnes colonnes

### 2. **Surprises**
- Le concern `WorkflowManageable` est testé mais jamais inclus dans aucun modèle!
- Beaucoup de modèles utilisent des enums string mais ne les déclarent pas correctement
- Les factories ImmoPromo utilisent parfois `:user` au lieu de `association :user`

### 3. **Patterns de code**
- Les enums doivent TOUJOURS être déclarés avec des valeurs string explicites:
  ```ruby
  enum status: { draft: 'draft', active: 'active' }  # BON
  enum status: [:draft, :active]  # MAUVAIS pour nos tests
  ```

- Les concerns testent souvent des méthodes qui devraient être dans le concern mais n'y sont pas

## 📋 Ordre de Correction Recommandé

### Phase 1: Quick Wins (1-2 heures)
1. **Ajouter WorkflowManageable au modèle Workflow** (fixe ~20 tests)
2. **Corriger la table dans addressable_spec.rb** (fixe 4 tests)
3. **Créer les factories manquantes principales** (fixe ~50 tests)

### Phase 2: Enums et Validations (2-3 heures)
1. **Déclarer tous les enums manquants** dans les modèles ImmoPromo
2. **Ajouter les validations manquantes** (presence, inclusion, etc.)
3. **Corriger les associations** (foreign_key, class_name, optional)

### Phase 3: Méthodes Métier (2-3 heures)
1. **Implémenter les méthodes de permission** (can_be_*_by?)
2. **Ajouter les méthodes de calcul** (total_cost, billable_hours, etc.)
3. **Implémenter les scopes manquants**

### Phase 4: Concerns Complexes (3-4 heures)
1. **Compléter Linkable concern** avec toutes les méthodes
2. **Finaliser Validatable concern**
3. **Corriger Treeable concern** pour les hiérarchies

## 🛠️ Commandes de Test Utiles

```bash
# Tester un modèle spécifique
docker-compose run --rm web bundle exec rspec spec/models/document_spec.rb --fail-fast

# Tester un concern
docker-compose run --rm web bundle exec rspec spec/models/concerns/addressable_spec.rb

# Tester tous les modèles ImmoPromo
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/models/

# Voir les colonnes d'une table
docker-compose run --rm web rails runner "puts Immo::Promo::Contract.column_names.sort"

# Vérifier les associations
docker-compose run --rm web rails runner "puts Document.reflect_on_all_associations.map { |a| [a.name, a.foreign_key] }"

# Lister toutes les tables
docker-compose run --rm web rails runner "puts ActiveRecord::Base.connection.tables.grep(/immo_promo/).sort"
```

## ⚠️ Pièges à Éviter

1. **Ne pas créer de migrations** si la colonne existe déjà dans le schema
2. **Toujours utiliser le préfixe `immo_promo_`** pour les factories du module
3. **Les enums avec colonnes string** doivent avoir des valeurs explicites
4. **Les tests de concerns** doivent sauvegarder les instances avant de tester
5. **Les associations polymorphes** nécessitent both `*_type` et `*_id`

## 📊 Métriques de Progression

- **Avant**: 406 échecs / 1111 tests (63% de succès)
- **Après Phase 1**: ~336 échecs estimés (70% de succès)
- **Après Phase 2**: ~200 échecs estimés (82% de succès)
- **Après Phase 3**: ~100 échecs estimés (91% de succès)
- **Après Phase 4**: 0 échec (100% de succès)

## 💡 Conseil Final

La majorité des échecs sont dus à des **problèmes de configuration** plutôt qu'à des bugs réels. En suivant ce guide méthodiquement, vous devriez pouvoir corriger tous les tests en 8-10 heures de travail concentré.

**Astuce**: Commencez par les quick wins pour voir rapidement des progrès, cela maintient la motivation!