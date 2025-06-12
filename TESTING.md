# 🧪 Guide de Testing DocuSphere

> **Dernière mise à jour** : 13 décembre 2025  
> **Status** : Production Ready avec ~95% de couverture

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Commandes Essentielles](#commandes-essentielles)
3. [Architecture des Tests](#architecture-des-tests)
4. [Tests Ruby/Rails](#tests-rubyrails)
5. [Tests JavaScript](#tests-javascript)
6. [Tests Système (Selenium)](#tests-système-selenium)
7. [Bonnes Pratiques](#bonnes-pratiques)
8. [Résolution de Problèmes](#résolution-de-problèmes)

## 🎯 Vue d'Ensemble

DocuSphere utilise une approche de testing complète avec :
- **RSpec** pour les tests Ruby/Rails
- **Bun** pour les tests JavaScript
- **Selenium** pour les tests système/intégration
- **FactoryBot** pour les fixtures de test
- **95%+ de couverture** de code

### Métriques Actuelles

| Type | Nombre | Status |
|------|--------|---------|
| Models (App) | 324 | ✅ 100% |
| Models (Engine) | 392 | ✅ 100% |
| Controllers (App) | 299 | ✅ 100% |
| Controllers (Engine) | 400+ | ✅ 100% |
| Components | 970 | ✅ 100% |
| Services | 189 | ✅ 100% |
| JavaScript | 140+ | ✅ 100% |
| System | 54 | ⚠️ 8/54 (UI changée) |

## 🚀 Commandes Essentielles

### Script Universel (RECOMMANDÉ)

```bash
# 🔥 UTILISER CES COMMANDES EN PRIORITÉ
./bin/test quick --fix      # Avant chaque commit
./bin/test ci --fix         # Simulation CI complète
./bin/test ci --fast --fix  # CI rapide (sans system tests)
./bin/test doctor           # Diagnostique problèmes
```

### Tests Ruby/Rails

```bash
# Tests en parallèle (RAPIDE - 4 processeurs)
docker-compose run --rm -e PARALLEL_TEST_PROCESSORS=4 web bundle exec parallel_rspec

# Tests séquentiels avec fail-fast
docker-compose run --rm web bundle exec rspec --fail-fast

# Test spécifique
docker-compose run --rm web bundle exec rspec spec/models/document_spec.rb:42

# Tests par type
docker-compose run --rm web bundle exec rspec spec/models
docker-compose run --rm web bundle exec rspec spec/controllers
docker-compose run --rm web bundle exec rspec spec/services
```

### Tests JavaScript

```bash
# Tous les tests JavaScript
bun test spec/javascript

# Test spécifique
bun test spec/javascript/controllers/ged_controller_spec.js

# Mode watch
bun test spec/javascript --watch
```

### Tests Système

```bash
# TOUJOURS utiliser le script dédié
./bin/system-test

# Test spécifique
./bin/system-test spec/system/document_upload_spec.rb

# Avec options RSpec
./bin/system-test --fail-fast
```

## 🏗️ Architecture des Tests

### Structure des Dossiers

```
spec/
├── controllers/        # Tests contrôleurs
├── models/            # Tests modèles
├── services/          # Tests services métier
├── components/        # Tests ViewComponents
├── jobs/              # Tests jobs asynchrones
├── policies/          # Tests Pundit policies
├── javascript/        # Tests JavaScript
│   ├── controllers/   # Tests Stimulus controllers
│   └── setup.js       # Configuration DOM pour Bun
├── system/            # Tests d'intégration Selenium
├── support/           # Helpers et configuration
├── factories/         # FactoryBot factories
└── fixtures/          # Fichiers de test
```

### Configuration Tests Parallèles

Les tests utilisent 4 bases de données pour l'exécution parallèle :
- `docusphere_test`
- `docusphere_test2`
- `docusphere_test3`
- `docusphere_test4`

**Setup initial** :
```bash
./bin/parallel_test_setup
```

## 💎 Tests Ruby/Rails

### Patterns Courants

#### Test de Modèle
```ruby
RSpec.describe Document, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:uploaded_by) }
  end
  
  describe 'associations' do
    it { should belong_to(:space) }
    it { should have_many(:versions) }
  end
  
  describe '#published?' do
    let(:document) { create(:document, status: 'published') }
    
    it 'returns true when status is published' do
      expect(document.published?).to be true
    end
  end
end
```

#### Test de Contrôleur
```ruby
RSpec.describe DocumentsController, type: :controller do
  let(:user) { create(:user) }
  let(:document) { create(:document, uploaded_by: user) }
  
  before { sign_in user }
  
  describe 'GET #show' do
    it 'returns success' do
      get :show, params: { id: document.id }
      expect(response).to have_http_status(:success)
    end
  end
end
```

#### Test de Service
```ruby
RSpec.describe DocumentProcessingService do
  let(:document) { create(:document, :with_file) }
  let(:service) { described_class.new(document) }
  
  describe '#process' do
    it 'generates thumbnail' do
      expect { service.process }
        .to change { document.has_thumbnail? }
        .from(false).to(true)
    end
  end
end
```

### Factories

```ruby
# spec/factories/documents.rb
FactoryBot.define do
  factory :document do
    title { Faker::Lorem.sentence }
    association :uploaded_by, factory: :user
    association :space
    
    trait :with_file do
      after(:build) do |doc|
        doc.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/sample.pdf')),
          filename: 'sample.pdf',
          content_type: 'application/pdf'
        )
      end
    end
    
    trait :published do
      status { 'published' }
      published_at { Time.current }
    end
  end
end
```

## 🟨 Tests JavaScript

### Configuration Bun

Les tests JavaScript utilisent Bun comme runtime. La configuration est dans :
- `bun.config.js` : Configuration générale
- `spec/javascript/setup.js` : Setup DOM avec jsdom

### Structure d'un Test Stimulus

```javascript
import '../setup.js'  // IMPORTANT: Toujours importer en premier
import { Application } from "@hotwired/stimulus"
import GedController from "../../../app/javascript/controllers/ged_controller"

describe("GedController", () => {
  let application
  let element
  
  beforeEach(() => {
    // Setup DOM
    document.body.innerHTML = `
      <div data-controller="ged">
        <button data-action="click->ged#openModal">Open</button>
        <div id="modal" class="hidden"></div>
      </div>
    `
    
    // Initialize Stimulus
    application = Application.start()
    application.register("ged", GedController)
    
    element = document.querySelector('[data-controller="ged"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  it("opens modal on button click", () => {
    const button = element.querySelector('button')
    const modal = document.getElementById('modal')
    
    button.click()
    
    expect(modal.classList.contains('hidden')).toBe(false)
  })
})
```

### Mocking dans les Tests JS

```javascript
// Mock fetch
beforeEach(() => {
  fetch.mock.mockClear()
  fetch.mock.mockResolvedValue({
    status: 200,
    json: async () => ({ success: true })
  })
})

// Usage
it("submits form via AJAX", async () => {
  const form = document.getElementById('form')
  form.dispatchEvent(new Event('submit'))
  
  await new Promise(resolve => setTimeout(resolve, 100))
  
  expect(fetch.mock.calls.length).toBe(1)
  expect(fetch.mock.calls[0][0]).toBe('/api/endpoint')
})
```

## 🌐 Tests Système (Selenium)

### Configuration

Les tests système utilisent Selenium dans un container Docker séparé :
- **ARM64** (Mac M1/M2) : `seleniarm/standalone-chromium`
- **x86_64** (Intel/CI) : `selenium/standalone-chrome`

### Écriture de Tests Système

```ruby
require 'rails_helper'

RSpec.describe "Document Upload", type: :system do
  let(:user) { create(:user) }
  
  before do
    sign_in user
  end
  
  it "uploads a document successfully", js: true do
    visit new_document_path
    
    fill_in "Titre", with: "Mon Document"
    attach_file "Fichier", Rails.root.join("spec/fixtures/files/sample.pdf")
    
    click_button "Téléverser"
    
    expect(page).to have_content("Document téléversé avec succès")
    expect(page).to have_content("Mon Document")
  end
end
```

### Debugging Tests Système

```bash
# Voir le navigateur en temps réel
open http://localhost:7900

# Mode debug dans le test
it "complex test", debug: true do
  # Le navigateur sera visible
end

# Pause dans le test
DEBUG=1 ./bin/system-test spec/system/my_test_spec.rb
```

## 📚 Bonnes Pratiques

### 1. Organisation des Tests

- **Un fichier de test par fichier de code**
- **Structure miroir** : `app/models/document.rb` → `spec/models/document_spec.rb`
- **Tests isolés** : Chaque test doit être indépendant
- **Noms descriptifs** : `describe` le comportement, pas l'implémentation

### 2. Performance

- **Utiliser les traits FactoryBot** pour éviter les créations inutiles
- **Préférer `let` à `let!`** sauf si nécessaire
- **Utiliser `build` plutôt que `create`** quand possible
- **Tests parallèles** pour les suites larges

### 3. Maintenabilité

- **DRY mais lisible** : Extraire les helpers communs
- **Éviter les mocks excessifs** : Préférer les vrais objets
- **Tests documentés** : Les tests servent de documentation
- **Mise à jour régulière** : Maintenir les tests avec le code

### 4. Coverage

- **Viser 90%+** de couverture
- **Tester les edge cases** pas seulement le happy path
- **Ne pas tester Rails** : Focus sur votre logique métier
- **Tests significatifs** : La qualité prime sur la quantité

## 🔧 Résolution de Problèmes

### Erreurs Fréquentes

#### "Factory not registered"
```ruby
# Vérifier que la factory existe
# spec/factories/documents.rb
FactoryBot.define do
  factory :document do
    # ...
  end
end
```

#### "undefined method" dans les tests
```ruby
# Si un test cherche une méthode qui n'existe pas :
# 1. NE PAS supprimer le test
# 2. Implémenter la méthode dans le modèle/service
# Les tests documentent le comportement attendu !
```

#### Tests JavaScript qui échouent
```javascript
// Vérifier que setup.js est importé
import '../setup.js'  // TOUJOURS en premier

// Vérifier les globals nécessaires
global.MouseEvent = dom.window.MouseEvent
global.Element = dom.window.Element
```

#### Tests système timeout
```bash
# Augmenter le timeout dans spec/support/capybara.rb
Capybara.default_max_wait_time = 10  # secondes

# Ou utiliser un timeout spécifique
find('.element', wait: 20)
```

### Debug Avancé

```ruby
# Sauvegarder screenshot
save_screenshot('/tmp/debug.png')

# Afficher le HTML
puts page.html

# Pause interactive
binding.pry  # Nécessite pry-rails

# Logs JavaScript
page.driver.browser.logs.get(:browser)
```

## 📊 Rapports et Métriques

### Coverage
```bash
# Générer rapport de couverture
COVERAGE=true bundle exec rspec

# Voir le rapport
open coverage/index.html
```

### Performance
```bash
# Profiler les tests lents
bundle exec rspec --profile 10
```

### Documentation
```bash
# Générer documentation depuis les tests
bundle exec rspec --format documentation
```

## 🔄 Intégration Continue

Les tests sont automatiquement exécutés sur GitHub Actions :
- Tests unitaires en parallèle
- Tests système avec Selenium
- Analyse de sécurité (Brakeman)
- Vérification des dépendances

Configuration dans `.github/workflows/ci.yml`

---

## 📌 Règles Fondamentales

1. **TOUJOURS** écrire les tests AVANT ou AVEC le code
2. **JAMAIS** pusher du code non testé
3. **TOUJOURS** faire passer les tests avant de merger
4. **JAMAIS** commenter ou supprimer un test qui échoue sans comprendre pourquoi

> 💡 **Rappel** : Les tests ne sont pas une corvée, ils sont votre filet de sécurité et votre documentation vivante !