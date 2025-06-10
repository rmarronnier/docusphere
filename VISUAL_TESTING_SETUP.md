# Configuration du Test Visuel pour Docusphere

## 1. Lookbook - Prévisualisation des Composants ✅ INSTALLÉ

### État actuel
- **Lookbook 2.3** installé et configuré
- Route montée sur `/rails/lookbook`
- Previews créées pour tous les composants principaux
- Documentation complète dans `docs/LOOKBOOK_GUIDE.md`

### Accès
```bash
# Démarrer l'application avec accès aux ports
docker-compose run --rm --service-ports web

# Accéder à Lookbook
open http://localhost:3000/rails/lookbook
```

### Composants avec previews
- ✅ DataGridComponent (11 previews)
- ✅ ButtonComponent (8 previews)
- ✅ CardComponent (5 previews)
- ✅ AlertComponent (7 previews)
- ✅ ModalComponent (6 previews)
- ✅ EmptyStateComponent (8 previews)

### Guide complet
Voir `docs/LOOKBOOK_GUIDE.md` pour :
- Créer de nouvelles previews
- Utiliser les fonctionnalités avancées
- Débugger les problèmes
- Best practices

## 2. Screenshots Automatiques avec Capybara

### Configuration existante améliorée
```ruby
# spec/support/capybara.rb
RSpec.configure do |config|
  config.after(:each, type: :system) do |example|
    if example.exception
      # Sauvegarde automatique en cas d'échec
      filename = example.full_description.gsub(/[^A-Za-z0-9]/, '_')
      page.save_screenshot("tmp/screenshots/failures/#{filename}.png")
    end
  end
end
```

### Helper pour screenshots manuels
```ruby
# spec/support/screenshot_helper.rb
module ScreenshotHelper
  def take_ui_screenshot(name)
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    filename = "tmp/screenshots/ui/#{name}_#{timestamp}.png"
    page.save_screenshot(filename)
    puts "Screenshot saved: #{filename}"
  end
end
```

## 3. Script de Capture UI

```bash
#!/bin/bash
# bin/capture-ui

echo "Capturing UI components..."

docker-compose run --rm web bundle exec rails runner '
  require "capybara/dsl"
  include Capybara::DSL
  
  Capybara.current_driver = :chrome_headless
  
  # Capture des composants principaux
  visit "/rails/lookbook"
  save_screenshot("tmp/screenshots/components_gallery.png")
  
  # Capture des pages principales
  pages = {
    "/" => "home",
    "/ged" => "ged_dashboard",
    "/search" => "search",
    "/notifications" => "notifications"
  }
  
  pages.each do |path, name|
    visit path
    save_screenshot("tmp/screenshots/pages/#{name}.png")
  end
'

echo "Screenshots saved in tmp/screenshots/"
```

## 4. Partage des Screenshots

### Via Docker volumes
```yaml
# docker-compose.yml
services:
  web:
    volumes:
      - ./tmp/screenshots:/app/tmp/screenshots
```

### Script d'upload automatique
```ruby
# lib/tasks/screenshots.rake
namespace :screenshots do
  desc "Upload screenshots to temporary sharing service"
  task upload: :environment do
    Dir["tmp/screenshots/**/*.png"].each do |file|
      # Utiliser un service comme imgur ou imgbb
      puts "Uploading #{file}..."
      # Implementation de l'upload
    end
  end
end
```

## 5. Workflow Recommandé

1. **Développement**: Utiliser Lookbook pour prévisualiser les composants
2. **Test**: Capturer automatiquement les screenshots lors des tests
3. **Review**: Partager les screenshots via:
   - Commit dans un dossier `docs/ui-screenshots/`
   - Upload temporaire sur un service d'hébergement d'images
   - Montage d'un serveur web local pour partager les screenshots

## 6. Alternative: Visual Regression Testing

Pour aller plus loin:
- **Percy**: Service payant mais excellent pour la régression visuelle
- **BackstopJS**: Alternative gratuite et open source
- **Capybara-screenshot-diff**: Gem Ruby pour la comparaison visuelle

## Commandes Utiles

```bash
# Lancer Lookbook
docker-compose run --rm --service-ports web

# Capturer tous les composants
docker-compose run --rm web bin/capture-ui

# Nettoyer les vieux screenshots
find tmp/screenshots -name "*.png" -mtime +7 -delete
```