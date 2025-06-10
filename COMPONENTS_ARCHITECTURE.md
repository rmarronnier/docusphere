# Architecture des Composants ViewComponent

## Vue d'ensemble

L'application utilise ViewComponent pour créer des composants UI réutilisables et testables. Tous les composants sont prévisualisables via Lookbook en développement.

## Structure des fichiers

```
app/components/
├── application_component.rb          # Classe de base
├── ui/                               # Composants UI génériques
│   ├── data_grid_component.rb       # Composant principal de grille
│   ├── data_grid_component.html.erb
│   └── data_grid_component/         # Sous-composants
│       ├── action_component.rb
│       ├── cell_component.rb
│       ├── column_component.rb
│       ├── empty_state_component.rb
│       └── header_cell_component.rb
├── documents/                        # Composants spécifiques aux documents
├── forms/                           # Composants de formulaires
├── layout/                          # Composants de mise en page
└── navigation/                      # Composants de navigation

spec/components/
├── previews/                        # Previews Lookbook
│   └── ui/
│       ├── data_grid_component_preview.rb
│       ├── button_component_preview.rb
│       └── ...
└── ui/                             # Tests des composants
    ├── data_grid_component_spec.rb
    └── data_grid_component/
        ├── action_component_spec.rb
        └── ...
```

## Composants extraits (10/06/2025)

### 1. DataGridComponent

Composant principal pour l'affichage de données tabulaires.

**Architecture modulaire** :
- `ColumnComponent` : Configuration des colonnes
- `CellComponent` : Rendu et formatage des cellules
- `HeaderCellComponent` : En-têtes avec tri
- `ActionComponent` : Actions par ligne (3 styles)
- `EmptyStateComponent` : États vides personnalisables

**Utilisation** :
```ruby
render Ui::DataGridComponent.new(data: @documents) do |grid|
  grid.with_column(key: :title, label: "Titre", sortable: true)
  grid.with_column(key: :size, label: "Taille", format: :file_size)
  grid.with_column(key: :created_at, label: "Date", format: :date)
  
  grid.with_action(label: "Voir", path: ->(doc) { document_path(doc) })
  grid.with_action(label: "Modifier", path: ->(doc) { edit_document_path(doc) })
end
```

### 2. ActionComponent

Gère les actions sur les lignes avec trois styles d'affichage.

**Styles disponibles** :
- `:inline` - Liens simples alignés
- `:dropdown` - Menu déroulant
- `:buttons` - Boutons groupés

**Fonctionnalités** :
- Support des permissions Pundit
- Actions conditionnelles
- Confirmations
- Classes CSS personnalisables

### 3. CellComponent

Formate et affiche les données des cellules.

**Formats supportés** :
- `:currency` - Formatage monétaire
- `:percentage` - Pourcentages
- `:date` - Dates
- `:boolean` - Booléens (✓/✗)
- `:file_size` - Tailles de fichiers
- `Proc` - Formatage personnalisé

### 4. EmptyStateComponent

États vides personnalisables avec icônes.

**Icônes disponibles** :
- `document`, `folder`, `search`, `inbox`, `users`

**Modes** :
- Message simple avec icône
- Contenu HTML personnalisé
- Actions suggérées

## Patterns et conventions

### 1. Configuration fluide

```ruby
grid.configure_actions(style: :dropdown)
grid.with_action(label: "Edit", path: edit_path)
```

### 2. Slots ViewComponent

```ruby
renders_many :columns, ColumnComponent
renders_one :empty_state
```

### 3. Tests isolés

Chaque composant a ses propres tests :
```bash
# Tester un composant spécifique
docker-compose run --rm web bundle exec rspec spec/components/ui/data_grid_component_spec.rb

# Tester tous les sous-composants
docker-compose run --rm web bundle exec rspec spec/components/ui/data_grid_component/
```

### 4. Previews Lookbook

Accès : http://localhost:3000/rails/lookbook

Chaque composant a plusieurs previews :
- `default` - Utilisation de base
- `variants` - Toutes les variantes
- `with_*` - Avec options spécifiques
- `complex_example` - Cas d'usage avancé

## Création d'un nouveau composant

### 1. Créer le composant

```ruby
# app/components/ui/my_component.rb
class Ui::MyComponent < ApplicationComponent
  def initialize(title:, **options)
    @title = title
    @options = options
  end
  
  private
  attr_reader :title, :options
end
```

### 2. Créer le template

```erb
<!-- app/components/ui/my_component.html.erb -->
<div class="my-component">
  <h3><%= title %></h3>
  <%= content %>
</div>
```

### 3. Créer les tests

```ruby
# spec/components/ui/my_component_spec.rb
require 'rails_helper'

RSpec.describe Ui::MyComponent, type: :component do
  it "renders the title" do
    render_inline(described_class.new(title: "Test"))
    expect(page).to have_text("Test")
  end
end
```

### 4. Créer la preview

```ruby
# spec/components/previews/ui/my_component_preview.rb
class Ui::MyComponentPreview < Lookbook::Preview
  def default
    render Ui::MyComponent.new(title: "Exemple")
  end
end
```

## Bonnes pratiques

1. **Séparation des responsabilités** : Un composant = une responsabilité
2. **Composition** : Préférer la composition à l'héritage
3. **Tests** : Tester le rendu ET le comportement
4. **Documentation** : Utiliser les previews comme documentation vivante
5. **Accessibilité** : Inclure les attributs ARIA nécessaires
6. **Performance** : Éviter les calculs complexes dans le rendu

## Ressources

- [ViewComponent Documentation](https://viewcomponent.org/)
- [Lookbook Documentation](https://lookbook.build/)
- Guide Lookbook : `docs/LOOKBOOK_GUIDE.md`
- Tests visuels : `VISUAL_TESTING_SETUP.md`