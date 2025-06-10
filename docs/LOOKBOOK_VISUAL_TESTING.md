# Guide de Test Visuel avec Lookbook

## État Actuel (10/06/2025) - ✅ RÉSOLU

### ✅ Ce qui fonctionne

1. **Installation de Lookbook** - Gem installé et configuré ✅
2. **Route accessible** - `/rails/lookbook` répond correctement ✅
3. **Capture automatisée** - Script rake `lookbook:capture` fonctionnel ✅
4. **Infrastructure Selenium** - Docker Selenium opérationnel ✅
5. **Previews chargés** - 6 composants avec 48 scenarios détectés ✅
6. **URLs fonctionnelles** - Tous les previews accessibles ✅

### 🔧 Problèmes résolus

1. **Previews non chargés** - ✅ Déplacés vers `test/components/previews/` (convention Lookbook)
2. **Erreur ActionView** - ✅ Corrigé les paramètres des composants (`label:` → `text:`)
3. **Routes 404** - ✅ URLs correctes utilisées dans le script de capture
4. **Autoload des classes** - ✅ Configuration `autoload_paths` mise à jour

### 🔍 Diagnostic

Le problème principal est que Lookbook ne charge pas les previews malgré :
- Les fichiers présents dans `spec/components/previews/ui/`
- La configuration correcte dans `config/initializers/lookbook.rb`
- Le rechargement du serveur

## Solutions Alternatives

### 1. Test Visuel Manuel (Recommandé pour l'instant)

```bash
# Ouvrir Lookbook dans le navigateur
open http://localhost:3000/rails/lookbook

# Si les previews apparaissent, capturer manuellement :
# - Cmd+Shift+5 sur macOS pour capture d'écran
# - Sauvegarder dans tmp/screenshots/lookbook_manual/
```

### 2. Tests de Composants ViewComponent

Au lieu de Lookbook, utiliser directement les tests ViewComponent :

```ruby
# spec/components/ui/button_component_spec.rb
RSpec.describe Ui::ButtonComponent, type: :component do
  it "renders all variants" do
    [:primary, :secondary, :success, :danger].each do |variant|
      render_inline(described_class.new(label: "Test", variant: variant))
      expect(page).to have_button("Test")
      # Capture screenshot si nécessaire
      page.save_screenshot("tmp/screenshots/components/button_#{variant}.png")
    end
  end
end
```

### 3. Storybook Alternative

Si Lookbook continue à poser problème, considérer Storybook :

```bash
# Installation
yarn add --dev @storybook/react @storybook/builder-webpack5

# Configuration pour Rails ViewComponents
# Voir : https://github.com/jonspalmer/view_component_storybook
```

## Capture Automatisée Fonctionnelle

Malgré les problèmes de preview, la capture automatisée fonctionne :

```bash
# Exécuter la capture (même si elle capture des pages d'erreur)
docker-compose run --rm web rake lookbook:capture

# Les screenshots sont sauvés dans :
# tmp/screenshots/lookbook_automated/
```

## Résolution des Problèmes Lookbook

### Étapes à essayer :

1. **Vérifier la syntaxe des previews**
   ```bash
   docker-compose run --rm web rails runner "
     Dir['spec/components/previews/**/*_preview.rb'].each do |file|
       begin
         load file
         puts \"✅ #{file}\"
       rescue => e
         puts \"❌ #{file}: #{e.message}\"
       end
     end
   "
   ```

2. **Mode debug Lookbook**
   ```ruby
   # config/initializers/lookbook.rb
   config.lookbook.debug = true
   config.lookbook.logger = Logger.new(STDOUT)
   ```

3. **Vérifier les dépendances**
   ```bash
   docker-compose run --rm web bundle exec rails runner "
     puts 'ViewComponent: ' + ViewComponent::VERSION
     puts 'Lookbook: ' + Lookbook::VERSION
     puts 'Rails: ' + Rails.version
   "
   ```

## Prochaines Étapes Recommandées

1. **Court terme** : Utiliser les tests ViewComponent pour la validation visuelle
2. **Moyen terme** : Déboguer pourquoi Lookbook ne charge pas les previews
3. **Long terme** : Évaluer si Storybook serait plus adapté

## Scripts Utiles

### Capture manuelle avec Selenium
```python
# capture_components.py
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

options = Options()
options.add_argument("--window-size=1400,1024")

driver = webdriver.Remote(
    command_executor='http://localhost:4444/wd/hub',
    options=options
)

# Capturer la page d'accueil
driver.get("http://localhost:3000")
driver.save_screenshot("home.png")

driver.quit()
```

### Test de rendu des composants
```bash
# Tester le rendu de tous les composants
docker-compose run --rm web bundle exec rspec spec/components/ --format documentation
```

## Conclusion

Bien que Lookbook soit installé et partiellement fonctionnel, il nécessite un débogage supplémentaire pour charger correctement les previews. En attendant, les alternatives proposées permettent de valider visuellement les composants.