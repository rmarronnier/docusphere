# Types de tests qui auraient pu détecter l'erreur "undefined method 'accessible_documents'"

Cette documentation montre différents types de tests qui auraient pu capturer l'erreur `NoMethodError: undefined method 'accessible_documents' for #<User>` dans `HomeController#index`.

## 1. Test Controller (Request Spec)

Le plus direct - teste l'action complète du contrôleur.

```ruby
# spec/controllers/home_controller_spec.rb ou spec/requests/home_spec.rb
RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    context 'when user is signed in' do
      let(:user) { create(:user) }
      
      before { sign_in user }
      
      it 'successfully renders the dashboard' do
        # Ce test aurait échoué avec NoMethodError
        get :index
        
        expect(response).to have_http_status(:success)
        expect(response).to render_template('dashboard')
      end
      
      it 'loads accessible documents' do
        # Test plus spécifique qui aurait clairement identifié le problème
        get :index
        
        expect(assigns(:accessible_documents)).to be_present
      end
    end
  end
end
```

**Avantages:**
- Détecte immédiatement l'erreur lors de l'exécution de l'action
- Message d'erreur clair: `NoMethodError: undefined method 'accessible_documents'`
- Test rapide à exécuter

## 2. Test d'Intégration (System/Feature Spec)

Teste le parcours utilisateur complet avec Capybara.

```ruby
# spec/system/dashboard_spec.rb ou spec/features/dashboard_spec.rb
RSpec.describe 'Dashboard', type: :system do
  let(:user) { create(:user) }
  
  before do
    sign_in user
  end
  
  it 'displays the dashboard when user is logged in' do
    # Ce test aurait échoué lors de la visite
    visit root_path
    
    expect(page).to have_content('Tableau de bord')
    expect(page).to have_css('.dashboard-container')
  end
  
  it 'shows accessible documents section' do
    # Test plus spécifique pour la section documents
    create(:document, uploaded_by: user)
    
    visit root_path
    
    expect(page).to have_css('.accessible-documents')
    expect(page).to have_content('Documents accessibles')
  end
end
```

**Avantages:**
- Teste le comportement réel de l'utilisateur
- Capture aussi les erreurs de rendu de vue
- Détecte les problèmes d'intégration

## 3. Test Unitaire du Modèle

Vérifie que la méthode existe sur le modèle.

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe '#accessible_documents' do
    let(:user) { create(:user) }
    
    it 'responds to accessible_documents method' do
      # Test basique de présence de méthode
      expect(user).to respond_to(:accessible_documents)
    end
    
    it 'returns documents accessible to the user' do
      # Test du comportement attendu
      owned_doc = create(:document, uploaded_by: user)
      shared_doc = create(:document)
      create(:document_share, document: shared_doc, shared_with: user)
      other_doc = create(:document)
      
      accessible = user.accessible_documents
      
      expect(accessible).to include(owned_doc, shared_doc)
      expect(accessible).not_to include(other_doc)
    end
  end
end
```

**Avantages:**
- Test très ciblé sur la méthode
- Rapide à exécuter
- Documente le comportement attendu

## 4. Test de Contract/Interface

Vérifie que les objets respectent leurs interfaces.

```ruby
# spec/contracts/user_contract_spec.rb
RSpec.describe 'User Contract' do
  subject(:user) { create(:user) }
  
  it 'implements required document access methods' do
    # Liste des méthodes attendues sur User
    required_methods = [
      :accessible_documents,
      :documents,
      :shared_documents,
      :can_access_document?
    ]
    
    required_methods.each do |method|
      expect(user).to respond_to(method)
    end
  end
end
```

**Avantages:**
- Définit clairement l'API publique attendue
- Facilite la refactorisation
- Sert de documentation vivante

## 5. Test de Smoke/Sanity

Test rapide qui vérifie les fonctionnalités critiques.

```ruby
# spec/smoke/critical_paths_spec.rb
RSpec.describe 'Critical User Paths', type: :request do
  let(:user) { create(:user) }
  
  before { sign_in user }
  
  it 'user can access dashboard without errors' do
    # Test minimaliste mais efficace
    expect { get root_path }.not_to raise_error
    expect(response).to be_successful
  end
  
  it 'all critical pages load without errors' do
    critical_paths = [
      root_path,
      documents_path,
      spaces_path,
      profile_path
    ]
    
    critical_paths.each do |path|
      get path
      expect(response).to be_successful
    end
  end
end
```

**Avantages:**
- Exécution rapide avant déploiement
- Détecte les erreurs critiques
- Peut être exécuté fréquemment

## 6. Test de ViewComponent

Si l'erreur était dans un composant.

```ruby
# spec/components/document_list_component_spec.rb
RSpec.describe DocumentListComponent, type: :component do
  let(:user) { create(:user) }
  
  it 'renders with user accessible documents' do
    # Ce test aurait échoué si le composant appelait accessible_documents
    component = described_class.new(user: user)
    
    expect { render_inline(component) }.not_to raise_error
  end
  
  it 'handles missing accessible_documents gracefully' do
    # Test défensif
    component = described_class.new(user: user)
    allow(user).to receive(:accessible_documents).and_raise(NoMethodError)
    
    rendered = render_inline(component)
    
    expect(rendered.to_html).to include('Aucun document')
  end
end
```

**Avantages:**
- Isole les tests de composants
- Plus rapide que les tests système
- Facilite le TDD pour les composants

## 7. Test de Régression Spécifique

Après avoir corrigé le bug, ajouter un test pour éviter la régression.

```ruby
# spec/regression/accessible_documents_spec.rb
RSpec.describe 'Accessible Documents Regression', type: :request do
  let(:user) { create(:user) }
  
  before { sign_in user }
  
  it 'does not call undefined method accessible_documents' do
    # Test explicite contre la régression
    expect(user).not_to receive(:accessible_documents)
    
    get root_path
    
    expect(response).to be_successful
  end
  
  it 'user model does not have accessible_documents method' do
    # Vérifie que la méthode n'existe pas (si c'est voulu)
    expect(user).not_to respond_to(:accessible_documents)
  end
  
  it 'dashboard loads without calling removed methods' do
    # Surveillance des méthodes supprimées
    removed_methods = [:accessible_documents, :viewable_documents, :editable_documents]
    
    removed_methods.each do |method|
      expect(user).not_to receive(method)
    end
    
    get root_path
    expect(response).to be_successful
  end
end
```

**Avantages:**
- Prévient le retour du bug
- Documente les décisions d'architecture
- Test spécifique et ciblé

## Bonnes Pratiques pour Éviter ce Type d'Erreur

### 1. Tests Pre-Commit

Automatiser les tests avant chaque commit.

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Lance les tests du controller modifié
if git diff --cached --name-only | grep -q "app/controllers/"; then
  echo "Running controller tests..."
  docker-compose run --rm web bundle exec rspec spec/controllers/ --fail-fast
  if [ $? -ne 0 ]; then
    echo "Controller tests failed. Please fix before committing."
    exit 1
  fi
fi

# Lance les tests du modèle modifié
if git diff --cached --name-only | grep -q "app/models/"; then
  echo "Running model tests..."
  docker-compose run --rm web bundle exec rspec spec/models/ --fail-fast
  if [ $? -ne 0 ]; then
    echo "Model tests failed. Please fix before committing."
    exit 1
  fi
fi
```

### 2. Tests en CI/CD

Configuration GitHub Actions pour détecter les erreurs.

```yaml
# .github/workflows/test.yml
name: Test Suite
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run controller tests
      run: docker-compose run --rm web bundle exec rspec spec/controllers/
      
    - name: Run system tests
      run: docker-compose run --rm web bundle exec rspec spec/system/
      
    - name: Run smoke tests
      run: docker-compose run --rm web bundle exec rspec spec/smoke/ --tag smoke
```

### 3. Tests de Contrat d'API Interne

Définir et vérifier les interfaces publiques.

```ruby
# spec/api/internal_contracts_spec.rb
RSpec.describe 'Internal API Contracts' do
  describe 'User model interface' do
    let(:user) { User.new }
    
    # Définir explicitement l'interface attendue
    EXPECTED_USER_METHODS = %i[
      documents
      document_shares
      document_validations
      # accessible_documents # Commenté si la méthode n'existe pas
    ].freeze
    
    EXPECTED_USER_METHODS.each do |method|
      it "responds to #{method}" do
        expect(user).to respond_to(method)
      end
    end
  end
  
  describe 'Document access patterns' do
    let(:user) { create(:user) }
    
    it 'provides a way to get all accessible documents' do
      # Vérifier qu'il existe une façon d'obtenir les documents accessibles
      expect(user).to respond_to(:documents)
      expect(user).to respond_to(:shared_documents)
      
      # Ou une méthode alternative
      expect(Document).to respond_to(:accessible_by)
    end
  end
end
```

### 4. Documentation des Méthodes Publiques

Documenter clairement l'API publique du modèle.

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Public API - Ces méthodes sont utilisées par les controllers
  
  # @return [ActiveRecord::Relation<Document>] Documents uploaded by user
  has_many :documents, foreign_key: :uploaded_by_id
  
  # @return [ActiveRecord::Relation<Document>] Documents shared with user
  has_many :shared_documents, through: :document_shares, source: :document
  
  # @deprecated Use {#documents} and {#shared_documents} instead
  # @note Cette méthode a été supprimée dans la version 2.0
  # def accessible_documents
  #   Document.accessible_by(self)
  # end
  
  # Méthode alternative pour obtenir tous les documents accessibles
  # @return [ActiveRecord::Relation<Document>]
  def all_accessible_documents
    Document.where(
      id: documents.select(:id)
        .union(shared_documents.select(:id))
    )
  end
end
```

### 5. Utilisation de Rubocop Custom Cops

Créer des règles personnalisées pour détecter les appels à des méthodes supprimées.

```ruby
# .rubocop/cops/removed_methods_cop.rb
module RuboCop
  module Cop
    module Custom
      class RemovedMethods < Base
        MSG = 'Method `%<method>s` has been removed. Use %<alternative>s instead.'
        
        REMOVED_METHODS = {
          accessible_documents: 'documents + shared_documents',
          viewable_documents: 'documents.viewable',
          editable_documents: 'documents.editable'
        }.freeze
        
        def on_send(node)
          return unless REMOVED_METHODS.key?(node.method_name)
          
          add_offense(
            node,
            message: format(MSG, 
              method: node.method_name,
              alternative: REMOVED_METHODS[node.method_name]
            )
          )
        end
      end
    end
  end
end
```

## Résumé des Types de Tests

| Type de Test | Détection | Rapidité | Précision | Utilisation |
|--------------|-----------|----------|-----------|-------------|
| **Controller/Request** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Test primaire |
| **System/Feature** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | Test d'intégration |
| **Model Unit** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Test ciblé |
| **Contract** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Documentation vivante |
| **Smoke** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | Vérification rapide |
| **ViewComponent** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Si erreur dans composant |
| **Regression** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Prévention |

## Recommandations

1. **Minimum requis**: Tests Controller + Tests Model pour chaque fonctionnalité
2. **Idéal**: Ajouter des tests System pour les parcours critiques
3. **Excellence**: Inclure tests de Contract et Smoke tests
4. **Prévention**: Ajouter des tests de régression après chaque bug corrigé

Le plus important est d'avoir au moins un test qui couvre chaque action de controller et chaque méthode publique de modèle. Cela aurait permis de détecter l'erreur `undefined method 'accessible_documents'` avant qu'elle n'arrive en production.