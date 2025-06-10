# Plan de Stabilisation DocuSphere - Prochaine Session

## 🎯 Objectif Principal
Stabiliser l'application en corrigeant TOUS les tests qui échouent et en effectuant un refactoring ciblé pour éviter les régressions futures.

## 📊 État Actuel (10/06/2025)
- ✅ **Tests des modèles** : Tous passent
- ✅ **Tests des factories** : Tous passent (49 factories valides)
- ✅ **Tests des controllers** : Tous passent (251 exemples)
- ✅ **Tests des components** : DataGrid refactoré (102 tests)
- ✅ **Lookbook** : Installé pour tests visuels
- ❌ **Tests système** : À mettre à jour pour nouvelle UI
- ⚠️ **Code à refactorer** : Document model (580+ lignes)

## 🔧 Phase 1 : Correction des Tests Restants ✅ COMPLÉTÉE

### 1.1 Tests des Controllers ✅
- ✅ Corrigé les erreurs de routes
- ✅ Vérifié les policies et permissions
- ✅ Mis à jour les factories utilisées
- ✅ 251 tests passent

### 1.2 Tests Système ✅
```bash
docker-compose run --rm web bundle exec rspec spec/system/
```
- ✅ Corrigé Capybara host configuration
- ✅ Supprimé les colonnes inexistantes (share_expires_at, color)
- ✅ Mis à jour les vues et modèles

### 1.3 Tests des Services ✅
```bash
docker-compose run --rm web bundle exec rspec spec/services/
```
- ✅ Corrigé NotificationService (références organization)
- ✅ Corrigé AiClassificationService (méthodes privées)
- ✅ Tous les tests passent

### 1.4 Tests des Components ✅
```bash
docker-compose run --rm web bundle exec rspec spec/components/
```
- ✅ Corrigé ChartComponent test (animate-spin)
- ✅ Vérifié ViewComponent helpers
- ✅ Tous les tests passent

## 🧹 Phase 2 : Nettoyage Code Mort (1 jour)

### 2.1 Suppression Immédiate ✅
- ❌ ~~Supprimer `app/models/document_version.rb`~~ (GARDÉ - utile pour PaperTrail)
- ✅ Supprimé concern `Uploadable` (non utilisé)
- ✅ Supprimé concern `Storable` (non utilisé)
- [ ] Nettoyer les méthodes dupliquées dans `Authorizable`

### 2.2 Refactoring Validatable ✅
- ✅ Migration vers associations polymorphes
- ✅ Retiré le code spécifique à Document
- ✅ Créé une interface générique
- ✅ Mis à jour ValidationRequest et DocumentValidation
- ✅ Mis à jour NotificationService
- ✅ Tous les tests passent

## 🏗️ Phase 3 : Refactoring Prioritaire (3-4 jours)

### 3.1 Décomposition du modèle Document (URGENT) ✅
Créer les concerns suivants :
- ✅ `Document::Lockable` - Toute la logique de verrouillage
- ✅ `Document::AiProcessable` - Classification et extraction IA
- ✅ `Document::VirusScannable` - Scan antivirus
- ✅ `Document::Versionable` - Configuration PaperTrail
- ✅ `Document::Processable` - Pipeline de traitement

**Résultat** : Document réduit de 538 à 247 lignes !

### 3.2 Standardisation des Statuts ✅
- ✅ Choisi AASM comme standard (déjà utilisé par 4 modèles core)
- ✅ Créé Immo::Promo::WorkflowStates pour les modèles Immo::Promo
- ✅ Migré Phase, Task et Permit vers le nouveau système
- ✅ Supprimé WorkflowManageable (non utilisé)
- ✅ Ajouté colonne workflow_status pour la compatibilité

### 3.3 Unification owned_by?
- [ ] Créer une configuration par modèle
- [ ] Standardiser les noms d'attributs
- [ ] Mettre à jour tous les tests

## 🚀 Phase 4 : Optimisation Performance (2 jours)

### 4.1 Ajout d'Index
```ruby
# Migration pour les index manquants
add_index :authorizations, [:authorizable_type, :authorizable_id, :user_id]
add_index :authorizations, [:authorizable_type, :authorizable_id, :user_group_id]
add_index :documents, :storage_path
add_index :documents, [:space_id, :status]
```

### 4.2 Cache des Permissions
- [ ] Implémenter Redis cache pour `authorized_for?`
- [ ] Cache les paths dans Treeable
- [ ] Cache les calculs de progression

## 📋 Phase 5 : Documentation et Tests (1 jour)

### 5.1 Documentation
- [ ] Documenter tous les concerns
- [ ] Créer des diagrammes UML des relations
- [ ] Mettre à jour MODELS.md avec les changements

### 5.2 Tests de Non-Régression
- [ ] Créer une suite de tests critiques
- [ ] Automatiser avec GitHub Actions
- [ ] Ajouter des tests de performance

## 🎯 Checklist Avant Commit

Pour CHAQUE modification :
- [ ] Lancer les tests du modèle/concern modifié
- [ ] Vérifier les factories associées
- [ ] Lancer les tests des modèles qui utilisent le concern
- [ ] Mettre à jour la documentation
- [ ] Vérifier qu'aucun test existant ne régresse

## 📈 Métriques de Succès

- 100% des tests passent
- Aucune régression sur les tests existants
- Document model < 200 lignes
- Temps d'exécution des tests < 5 minutes
- Aucun warning au démarrage

## ⚠️ Points d'Attention

1. **WorkflowManageable** : Décider si on le garde ou le supprime
2. **Document#lock!** : Résoudre le conflit avec PaperTrail
3. **Tests parallèles** : Ne PAS utiliser sur CI
4. **Factories** : Toujours vérifier contre schema.rb

## 🔄 Ordre d'Exécution Recommandé

1. **Jour 1** : Phase 1.1 et 1.2 (Controllers + System tests)
2. **Jour 2** : Phase 1.3 et 1.4 (Services + Components)
3. **Jour 3** : Phase 2 (Nettoyage)
4. **Jour 4-5** : Phase 3.1 (Document refactoring)
5. **Jour 6** : Phase 3.2 et 3.3 (Standardisation)
6. **Jour 7** : Phase 4 (Performance)
7. **Jour 8** : Phase 5 (Documentation)

---

**⚠️ IMPORTANT** : Suivre WORKFLOW.md pour chaque modification !