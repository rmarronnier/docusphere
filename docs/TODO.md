# 📋 TODO - DocuSphere & ImmoPromo

> **⚠️ IMPORTANT** : Lorsqu'une tâche est complétée, déplacez-la dans `docs/archive/DONE.md` au lieu de la supprimer. Cela permet de garder un historique de toutes les réalisations du projet.

> **Instructions** : 
> 1. Marquez les tâches complétées avec ✅
> 2. Déplacez les sections entièrement terminées vers `docs/archive/DONE.md`
> 3. Ajoutez la date de complétion dans DONE.md
> 4. Gardez ce fichier focalisé sur les tâches EN COURS et À FAIRE

## 🚧 EN COURS / À FAIRE

### 🔥 URGENT : Finaliser Stabilisation
**Priorité : CRITIQUE** 🔴🔴🔴

#### Actions Prioritaires :
- ✅ **Refactorer Document model** : ~~580+ lignes~~ 232 lignes → 103 lignes (réduction 56%) - 11 concerns créés (11/06/2025)
- ✅ **Ajuster tests services engine** : Corriger incompatibilités schéma/service identifiées (11/06/2025)
- ✅ **Lancer tous tests non-système** : Exécuter TOUS les tests (hors système) et corriger TOUS les échecs (11/06/2025)
  - ✅ Tests modèles : 704 examples, 0 failures
  - ✅ Tests unitaires core : 1646 examples, 0 failures
  - ✅ Tests engine : 564 examples, 0 failures
  - ✅ **TOTAL : 2210 tests passants !**
- [ ] **Extraire concerns/services longs** : Fichiers > 200 lignes à refactorer en modules
- [ ] **Tests système ImmoPromo** : Mettre à jour pour nouvelle UI avec workflows métier complets
- [ ] **Workflows complexes** : Circuits validation multi-intervenants avec permissions croisées
- [ ] **Demo interactive** : Scénarios métier complets utilisables en présentation

### 🧪 Tests & Qualité Code
**Priorité : HAUTE** 🔴

#### Actions Complétées (11/06/2025) :
- ✅ **Vérifier tests contrôleurs engine** : Tous les contrôleurs Immo::Promo ont des tests complets
- ✅ **Compléter tests manquants** : 12 contrôleurs avec couverture complète
- ✅ **Extraction concerns fichiers longs** : 5 fichiers refactorisés avec tests
- ✅ **Migration pagy vers Kaminari** : Cohérence dans la pagination

#### Actions Restantes :
- [ ] **Tests d'intégration engine** : Workflows complets projets immobiliers
- [ ] **Tests système engine** : Interfaces utilisateur Immo::Promo

### 🔧 Refactoring & Stabilisation
**Priorité : HAUTE** 🔴

#### Actions Complétées (11/06/2025) :
- ✅ **Extraction concerns services longs** : 
  - PermitWorkflowController : PermitDashboardController extrait
  - FinancialDashboardController : VarianceAnalyzable concern
  - NotificationService : DocumentNotifications module
  - RiskMonitoringController : RiskAlertable concern
  - StakeholderAllocationService : 4 concerns (AllocationOptimizer, TaskCoordinator, ConflictDetector, AllocationAnalyzer)
- ✅ **Tests pour tous les concerns** : 51 nouveaux tests passants
- ✅ **Tests services engine manquants** : 6 services identifiés et tests créés (100% couverture)

#### Actions Restantes :
- [ ] **Refactorer Document model** : 580+ lignes → découper en concerns
- [ ] **Nettoyer code mort** : Uploadable, Storable, document_version.rb
- [ ] **Standardiser statuts** : AASM vs WorkflowManageable
- [ ] **Optimiser performances** : Ajouter cache et index manquants
- [ ] **Tests système** : Mettre à jour pour nouvelle UI

⚠️ **OBLIGATOIRE** : Suivre WORKFLOW.md pour éviter nouvelles régressions !


### 🧪 Tests système complexes multi-utilisateurs
**Priorité : HAUTE** 🔴

Créer des scénarios ambitieux testant workflows complets :

#### 📝 Scénarios à implémenter :
- [ ] **Workflow permis complet** : Dépôt → Instruction → Conditions → Levée réserves
- [ ] **Coordination multi-intervenants** : Conflits planning, dépendances, alertes
- [ ] **Validation budgets** : Circuit approbation hiérarchique avec seuils
- [ ] **Gestion des risques** : Détection → Plan action → Suivi efficacité
- [ ] **Notifications en cascade** : Actions déclenchant notifications multiples utilisateurs
- [ ] **Workflows documents** : Upload → Classification → Validation → Archivage

#### 🎭 Rôles et permissions :
- **Directeur** : Vue globale, validation budgets importants, approbation permis
- **Chef de projet** : Coordination complète, gestion planning, validation intervenants
- **Architecte** : Documents techniques, permis construire, coordination études
- **Commercial** : Réservations, relation clients, documents commerciaux
- **Contrôleur** : Validation budgets, conformité, audit trail



### 👑 Dashboard Superadmin avancé
**Priorité : MOYENNE** 🟡

Interface d'administration système complète :

#### 🛠️ Fonctionnalités administration :
- [ ] **Gestion utilisateurs/groupes** : CRUD complet, import/export, désactivation
- [ ] **Permissions granulaires** : Interface visuelle permissions par rôle/ressource
- [ ] **Mode maintenance** : Activation/désactivation avec message personnalisé
- [ ] **Feature flags** : Activation/désactivation fonctionnalités par environnement
- [ ] **Monitoring logs** : Interface consultation erreurs, filtrage, alertes
- [ ] **Notifications système** : Envoi messages ciblés ou broadcast
- [ ] **Configuration globale** : Settings application, limites, quotas

#### 📊 Métriques et monitoring :
- [ ] **Usage statistics** : Utilisateurs actifs, documents, projets, performances
- [ ] **Health checks** : Status services (DB, Redis, Elasticsearch, Sidekiq)
- [ ] **Backup status** : Monitoring sauvegardes, restauration
- [ ] **Security audit** : Tentatives connexion, permissions, actions sensibles

---

## 🎯 PROCHAINES ÉVOLUTIONS

### 🤖 Intelligence Artificielle
- **Classification automatique** documents avec ML
- **Extraction métadonnées** avancée (montants, dates, parties prenantes)
- **Prédictions** retards projets et dépassements budgets
- **Recommandations** optimisation planning et ressources

### 🌐 Intégrations Tierces
- **APIs cadastre** : Récupération automatique données parcelles
- **APIs urbanisme** : Vérification règles PLU en temps réel
- **Banques & assurances** : Intégration financement et garanties
- **Fournisseurs** : Catalogues matériaux, devis automatiques

### 📱 Applications Mobiles
- **App terrain** : Rapports chantier avec photos géolocalisées
- **App commercial** : Visites prospects avec documentation intégrée
- **Notifications push** : Alertes temps réel sur projets critiques

### 🔄 Automatisation Avancée
- **Workflows adaptatifs** : Processus qui s'ajustent selon contexte projet
- **Escalades automatiques** : Alertes hiérarchiques sur retards/problèmes
- **Reporting automatisé** : Génération rapports périodiques personnalisés

---

## 📅 Planning Recommandé

### Phase 1 - Finalisation (1 semaine) 🔴
1. Refactoring Document model
2. Tests système ImmoPromo  
3. Workflows validation complexes

### Phase 2 - Administration (1 semaine)
1. Dashboard superadmin
2. Monitoring et métriques
3. Feature flags système

### Phase 3 - Évolutions (Continu)
1. Intelligence artificielle
2. Intégrations tierces
3. Applications mobiles

---

**Dernière mise à jour** : 11 juin 2025  
**Statut global** : 90% terminé, développement actif  
**Priorité absolue** : Finaliser stabilisation (Document model refactoring et ajustement tests)