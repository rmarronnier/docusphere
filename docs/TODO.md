# 📋 TODO - DocuSphere & ImmoPromo

> **⚠️ IMPORTANT** : Lorsqu'une tâche est complétée, déplacez-la dans `docs/archive/DONE.md` au lieu de la supprimer. Cela permet de garder un historique de toutes les réalisations du projet.

> **Instructions** : 
> 1. Marquez les tâches complétées avec ✅
> 2. Déplacez les sections entièrement terminées vers `docs/archive/DONE.md`
> 3. Ajoutez la date de complétion dans DONE.md
> 4. Gardez ce fichier focalisé sur les tâches EN COURS et À FAIRE

## 🚧 EN COURS / À FAIRE

### 🔥 URGENT : Stabilisation Application
**Priorité : CRITIQUE** 🔴🔴🔴

Suite aux régressions découvertes le 09/06/2025, un plan de stabilisation est en cours.

#### Actions Complétées (10/06/2025) :
- ✅ **Tests Controllers** : Tous passent (251 exemples)
- ✅ **Tests Components (App)** : Tous passent (899 exemples)
- ✅ **Tests Components (ImmoPromo)** : Tous passent (71 exemples)
- ✅ **Architecture ViewComponent** : 5 composants extraits de DataGrid
- ✅ **Documentation** : Lookbook installé pour tests visuels
- ✅ **Nettoyage repository** : Documents obsolètes archivés/supprimés

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

### Phase 1 - Core Documentaire (2-3 semaines)
1. Intégration documents ImmoPromo
2. Workflows documentaires de base
3. Tests système fondamentaux

### Phase 2 - UI & UX (1-2 semaines)  
1. Amélioration interface utilisateur
2. Responsive design
3. Optimisations performance

### Phase 3 - Administration (1 semaine)
1. Dashboard superadmin
2. Monitoring et métriques
3. ~~Nettoyage repository~~ ✅

### Phase 4 - Évolutions (Continu)
1. Intelligence artificielle
2. Intégrations tierces
3. Applications mobiles

---

**Dernière mise à jour** : 10 juin 2025  
**Statut global** : 85% terminé, développement actif  
**Priorité absolue** : Finaliser stabilisation (Document model refactoring)