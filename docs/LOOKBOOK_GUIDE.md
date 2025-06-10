# Guide d'utilisation de Lookbook

## Qu'est-ce que Lookbook ?

Lookbook est un outil de développement qui permet de prévisualiser et documenter les composants ViewComponent de manière interactive. Il fournit une interface web pour explorer, tester et comprendre comment utiliser chaque composant.

## Accès à Lookbook

### Démarrer l'application avec Lookbook

```bash
# Démarrer tous les services avec accès aux ports
docker-compose run --rm --service-ports web

# L'application sera accessible sur http://localhost:3000
# Lookbook sera accessible sur http://localhost:3000/rails/lookbook
```

### URL directe
- **Development** : http://localhost:3000/rails/lookbook
- **Disponible uniquement en environnement de développement**

## Structure des Previews

Les previews sont organisées dans `spec/components/previews/` et suivent la structure des composants :

```
spec/components/previews/
└── ui/
    ├── data_grid_component_preview.rb
    ├── button_component_preview.rb
    ├── card_component_preview.rb
    ├── alert_component_preview.rb
    ├── modal_component_preview.rb
    └── empty_state_component_preview.rb
```

## Créer une Preview

### 1. Structure de base

```ruby
# spec/components/previews/ui/mon_component_preview.rb
class Ui::MonComponentPreview < Lookbook::Preview
  # Layout à utiliser (optionnel)
  layout "application"
  
  # @label Exemple par défaut
  def default
    render Ui::MonComponent.new(title: "Exemple")
  end
end
```

### 2. Annotations Lookbook

```ruby
# @label Titre affiché dans Lookbook
# @display viewport desktop  # Force l'affichage desktop
# @display theme dark       # Force le thème sombre
def exemple_methode
  # ...
end
```

### 3. Exemples avec variations

```ruby
class Ui::ButtonComponentPreview < Lookbook::Preview
  # Exemple simple
  def default
    render Ui::ButtonComponent.new(label: "Cliquez-moi")
  end
  
  # Plusieurs variations
  def variants
    content_tag :div, class: "space-y-4" do
      safe_join([
        render(Ui::ButtonComponent.new(label: "Primary", variant: :primary)),
        render(Ui::ButtonComponent.new(label: "Secondary", variant: :secondary)),
        render(Ui::ButtonComponent.new(label: "Danger", variant: :danger))
      ])
    end
  end
  
  # Avec paramètres dynamiques
  # @param text [String] "Texte du bouton"
  # @param variant [Symbol] select { choices: [:primary, :secondary, :danger] }
  # @param size [Symbol] select { choices: [:sm, :md, :lg] }
  def configurable(text: "Bouton", variant: :primary, size: :md)
    render Ui::ButtonComponent.new(label: text, variant: variant, size: size)
  end
end
```

## Utilisation de Lookbook

### 1. Navigation

- **Sidebar** : Liste tous les composants et leurs previews
- **Preview Panel** : Affiche le rendu du composant
- **Code Tab** : Montre le code source de la preview
- **Source Tab** : Montre le code source du composant
- **Notes Tab** : Documentation additionnelle

### 2. Fonctionnalités interactives

- **Viewport** : Tester la responsivité (mobile, tablet, desktop)
- **Theme** : Basculer entre thème clair et sombre
- **Inspect** : Voir le HTML généré
- **Copy** : Copier le code d'utilisation

### 3. Recherche

Utilisez la barre de recherche pour trouver rapidement un composant ou une preview spécifique.

## Bonnes pratiques

### 1. Nommage des méthodes

```ruby
def default           # Exemple de base
def with_options      # Avec des options
def variants          # Toutes les variantes
def states           # Différents états (hover, disabled, etc.)
def complex_example   # Exemple d'utilisation complexe
```

### 2. Organisation des previews

```ruby
# Grouper les exemples par logique
def default
def simple_variations
def with_icons
def complex_interactions
```

### 3. Données de test

```ruby
private

def sample_data
  # Utiliser Faker pour des données réalistes
  5.times.map do |i|
    {
      id: i + 1,
      name: Faker::Name.name,
      email: Faker::Internet.email
    }
  end
end
```

### 4. Documentation inline

```ruby
# @label Grille avec sélection
# @notes Permet de sélectionner plusieurs lignes
def with_selection
  # Preview code...
end
```

## Exemples de composants disponibles

### DataGrid Component
- Tableau de données avec tri, pagination, actions
- Previews : default, with_actions, with_formatting, empty_states

### Button Component
- Boutons avec variantes, tailles, états
- Previews : variants, sizes, with_icons, states

### Card Component
- Cartes pour organiser le contenu
- Previews : default, with_footer, complex_example

### Alert Component
- Messages d'alerte et notifications
- Previews : types, dismissible, with_actions

### Modal Component
- Fenêtres modales pour dialogues
- Previews : sizes, with_footer, form_modal

### EmptyState Component
- États vides personnalisables
- Previews : icon_variations, custom_content, search_empty

## Débuggage

### Logs Lookbook
```ruby
# Dans config/initializers/lookbook.rb
config.lookbook.debug = true
```

### Rechargement des previews
Les previews sont automatiquement rechargées en développement. Si ce n'est pas le cas :

```bash
# Redémarrer le serveur
docker-compose restart web
```

## Tips & Tricks

1. **Preview avec formulaires** : Utilisez `form_tag` avec `#` comme action
2. **Preview avec JavaScript** : Les contrôleurs Stimulus fonctionnent normalement
3. **Assets** : Les CSS Tailwind sont automatiquement chargés
4. **Helpers** : Tous les helpers Rails sont disponibles dans les previews

## Ressources

- [Documentation Lookbook](https://lookbook.build/guide/)
- [ViewComponent](https://viewcomponent.org/)
- Code des previews : `spec/components/previews/`
- Configuration : `config/initializers/lookbook.rb`