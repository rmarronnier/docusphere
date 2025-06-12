# Stratégie de Correction des Tests

## 1. Analyse par type d'erreur

### A. Erreurs de Factory
**Symptôme**: `Factory not registered` ou `undefined method 'field=' for Factory`
**Solution**:
1. Vérifier le schema pour les colonnes réelles
2. Créer/corriger la factory avec les bons champs
3. Utiliser les associations correctes

### B. Erreurs d'Enum
**Symptôme**: `Undeclared attribute type for enum`
**Solution**:
1. Vérifier si la colonne existe dans le schema
2. Si oui, vérifier le type (string ou integer)
3. Ajouter la colonne si manquante ou déclarer l'enum correctement

### C. Méthodes manquantes
**Symptôme**: `undefined method 'method_name'`
**Solution**:
1. Vérifier si c'est une méthode métier → l'implémenter dans le modèle
2. Si c'est un attribut → vérifier le schema et ajouter la migration si nécessaire

### D. Associations incorrectes
**Symptôme**: Erreurs sur `belong_to`, `has_many`, etc.
**Solution**:
1. Vérifier les foreign keys dans le schema
2. Ajuster les associations dans le modèle
3. Mettre à jour les specs

## 2. Processus de correction par priorité

### Phase 1: Infrastructure (Priorité HAUTE)
- [ ] Corriger toutes les factories manquantes
- [ ] Ajouter les colonnes manquantes via migrations
- [ ] Corriger les enums mal déclarés

### Phase 2: Modèles de base (Priorité MOYENNE)
- [ ] Document, User, Organization, Space, Folder
- [ ] WorkflowSubmission, Workflow
- [ ] Les concerns principaux

### Phase 3: Module ImmoPromo (Priorité MOYENNE)
- [ ] Project, Phase, Task
- [ ] Stakeholder, Permit, Budget
- [ ] Les associations entre modèles

### Phase 4: Fonctionnalités avancées (Priorité BASSE)
- [ ] Méthodes de calcul complexes
- [ ] Scopes spécialisés
- [ ] Callbacks et validations custom

## 3. Approche pratique

### Pour chaque modèle:
1. **Lister les colonnes du schema**
   ```bash
   docker-compose run --rm web rails c
   Model.column_names
   ```

2. **Comparer avec le modèle**
   - Validations correspondent aux colonnes ?
   - Associations ont les foreign keys ?
   - Enums ont les colonnes support ?

3. **Ajuster dans cet ordre**
   - D'abord: Migrations pour ajouter colonnes manquantes
   - Ensuite: Modèle pour corriger associations/validations
   - Enfin: Specs et factories pour matcher la réalité

## 4. Commandes utiles

```bash
# Voir les colonnes d'une table
docker-compose run --rm web rails runner "puts Document.column_names"

# Vérifier les foreign keys
docker-compose run --rm web rails runner "puts Document.reflect_on_all_associations.map(&:foreign_key)"

# Tester un modèle spécifique
docker-compose run --rm web bundle exec rspec spec/models/document_spec.rb --fail-fast

# Générer une migration
docker-compose run --rm web rails g migration AddMissingFieldsToDocuments field1:string field2:integer
```

## 5. Patterns de correction courants

### Factory avec associations
```ruby
factory :document do
  title { "Test Document" }
  association :uploaded_by, factory: :user
  association :space
  
  # Trait pour les tests nécessitant un fichier
  trait :with_file do
    after(:build) do |doc|
      doc.file.attach(
        io: StringIO.new('test'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
    end
  end
end
```

### Enum correctement déclaré
```ruby
# Si la colonne existe et est string
enum status: {
  draft: 'draft',
  published: 'published',
  archived: 'archived'
}

# Si la colonne n'existe pas
attribute :status, :string, default: 'draft'
enum status: { draft: 'draft', published: 'published' }
```

### Concern avec dépendances
```ruby
module MyConsern
  extend ActiveSupport::Concern
  
  included do
    # Vérifier que les colonnes existent
    validates :field, presence: true if column_names.include?('field')
    
    # Scopes conditionnels
    scope :active, -> { where(active: true) } if column_names.include?('active')
  end
end
```