# ImmoPromo - Module de Gestion de Projets Immobiliers

ImmoPromo est un engine Rails offrant une solution complète de pilotage de projets immobiliers pour Docusphere. Il permet d'orchestrer tous les aspects techniques, juridiques et organisationnels des opérations immobilières.

## Description

Ce module fournit un système complet de gestion de projets immobiliers couvrant l'intégralité du cycle de vie d'un projet : de la conception à la livraison, en passant par les autorisations administratives, la construction et la commercialisation.

## 🚀 Démarrage Rapide

### 1. Installation et Configuration

```bash
# Installer les dépendances
docker-compose run --rm web bundle install

# Installer les migrations
docker-compose run --rm web rails immo_promo:install:migrations
docker-compose run --rm web rails db:migrate

# Créer l'environnement de démonstration avec des données de test
docker-compose run --rm web rails immo_promo:setup_demo

# Démarrer le service
docker-compose up -d
```

### 2. Accès et Test

- **URL d'accès** : http://localhost:3000/immo/promo/projects
- **Comptes de démonstration** (mot de passe : `test123`) :
  - `directeur@promotex.fr` - Directeur (super_admin)
  - `chef.projet@promotex.fr` - Chef de projet (admin)
  - `architecte@promotex.fr` - Architecte (manager)
  - `commercial@promotex.fr` - Commercial (user)
  - `controle@promotex.fr` - Contrôleur (manager)

### 3. Données de Démonstration

L'environnement de test inclut :
- **3 projets réalistes** : Résidence Les Jardins (en construction), Tour Horizon (planification), Villa Lumière (terminé)
- **Budgets complets** : 8.5M€, 25M€, 2.8M€ avec lignes détaillées
- **Intervenants** : Architectes, entrepreneurs, bureaux d'études
- **Permis** : Permis de construire, autorisations de voirie
- **Phases et tâches** : Workflow complet avec assignations

## 🎯 Workflows Utilisateur

Chaque profil utilisateur a accès à des fonctionnalités spécialisées :

### 👔 **Directeur** (super_admin)
- Vue globale sur tous les projets
- Validation des budgets et contrats
- Approbation des permis
- Tableaux de bord financiers consolidés

### 🏗️ **Chef de Projet** (admin)
- Gestion complète des projets
- Coordination des intervenants
- Suivi des permis et autorisations
- Planification et pilotage

### 🎨 **Architecte** (manager)
- Tâches d'études et conception
- Suivi des permis de construire
- Coordination technique
- Validation des spécifications

### 💼 **Commercial** (user)
- Gestion des réservations
- Suivi de l'inventaire des lots
- Pipeline commercial
- Reporting des ventes

### 📊 **Contrôleur** (manager)
- Suivi budgétaire et financier
- Analyse des écarts
- Reporting de gestion
- Contrôle de conformité

## 🧪 Tests et Qualité

### Couverture des Tests

Le module dispose d'une suite de tests complète :

```bash
# Lancer tous les tests (recommandé)
docker-compose run --rm -e PARALLEL_TEST_PROCESSORS=4 web bundle exec parallel_rspec engines/immo_promo/spec

# Tests par catégorie
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/models      # Tests modèles
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/controllers # Tests contrôleurs  
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/services    # Tests services
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/system      # Tests système
```

### État Actuel des Tests

- ✅ **Modèles** : 140 exemples, 0 échecs
- ✅ **Contrôleurs** : 43 exemples, 0 échecs  
- ✅ **Services** : ~69% de réussite (en amélioration continue)
- ✅ **Tests système** : Navigation et interfaces fonctionnelles

## 📋 Gestion des Données

### Commandes Utiles

```bash
# Créer l'environnement de démonstration complet
rails immo_promo:setup_demo

# Charger uniquement les seeds
rails immo_promo:db:seed

# Nettoyer et recréer les données
rails immo_promo:db:reseed
```

### Structure des Seeds

Les seeds créent automatiquement :
- **Organisation** : Promotex Immobilier
- **5 utilisateurs** avec profils et permissions différents
- **3 projets** avec données réalistes
- **Phases, tâches, permis, budgets** interconnectés
- **Workflow complet** de démonstration

## 🏗️ Fonctionnalités Principales

### Gestion de Projets
- **Types de projets** : Résidentiel, commercial, mixte, industriel
- **Planification par phases** : Études, permis, construction, réception, livraison
- **Suivi en temps réel** : Timeline interactive avec détection des retards
- **Dashboard centralisé** : Vue d'ensemble avec métriques clés

### Coordination des Intervenants
- **Annuaire centralisé** : Architectes, bureaux d'études, entreprises
- **Gestion des contrats** : Suivi des contrats et avenants
- **Certifications** : Contrôle des habilitations et assurances
- **Historique complet** : Traçabilité des interactions

### Permis et Autorisations
- **Workflow intégré** : Gestion du processus de permis de construire
- **Suivi des conditions** : Gestion des prescriptions et réserves
- **Alertes réglementaires** : Rappels des échéances administratives
- **Documents associés** : Centralisation des pièces justificatives

### Suivi Financier
- **Budgets multi-versions** : Initial, révisé, final
- **Ventilation par postes** : Foncier, études, travaux, équipements
- **Analyse des écarts** : Comparaison prévisionnel/réel
- **Reporting financier** : Tableaux de bord et exports

### Gestion des Tâches
- **Création et assignation** : Tâches granulaires avec responsables
- **Dépendances** : Gestion des prérequis et enchaînements  
- **Suivi d'avancement** : Pourcentage et temps passé
- **Alertes automatiques** : Notifications sur les retards

## 🔧 Architecture Technique

### Structure du Module

```ruby
# Modèles principaux
Immo::Promo::Project       # Projets immobiliers
Immo::Promo::Phase         # Phases du projet
Immo::Promo::Task          # Tâches détaillées
Immo::Promo::Stakeholder   # Parties prenantes
Immo::Promo::Permit        # Permis et autorisations
Immo::Promo::Budget        # Budgets
Immo::Promo::Contract      # Contrats
Immo::Promo::Milestone     # Jalons

# Services métier
Immo::Promo::ProjectManagerService         # Gestion de projet
Immo::Promo::PermitTrackerService         # Suivi des permis
Immo::Promo::StakeholderCoordinatorService # Coordination
Immo::Promo::ProjectBudgetService         # Gestion budgétaire
```

### Concerns Réutilisables

Le module utilise des concerns modulaires pour la cohérence :

- **Schedulable** : Gestion des dates et planning
- **Authorizable** : Permissions et autorisations
- **Addressable** : Gestion des adresses
- **WorkflowManageable** : Gestion des workflows

## 🔒 Sécurité et Permissions

### Système de Permissions

```ruby
# Permissions de base
'immo_promo:access'     # Accès au module
'immo_promo:manage'     # Gestion des projets
'immo_promo:admin'      # Administration complète

# Contrôle d'accès
- Isolation par organisation
- Permissions granulaires par ressource
- Audit trail complet avec gem 'audited'
- Policies Pundit pour chaque modèle
```

### Exemple d'Utilisation

```ruby
# Vérification des permissions
user.can_access_immo_promo?      # Accès au module
user.can_manage_project?(project) # Gestion d'un projet
user.accessible_projects          # Projets accessibles

# Dans les contrôleurs
authorize @project, :show?        # Pundit policy
@projects = policy_scope(Project) # Scope filtré
```

## 🌐 API et Routes

### Routes Principales

```
# Projets
GET    /immo/promo/projects                    # Liste des projets
POST   /immo/promo/projects                    # Créer un projet
GET    /immo/promo/projects/:id                # Détails d'un projet
PUT    /immo/promo/projects/:id                # Mettre à jour

# Phases et tâches
GET    /immo/promo/projects/:id/phases         # Phases du projet
GET    /immo/promo/projects/:id/tasks          # Tâches du projet

# Intervenants
GET    /immo/promo/projects/:id/stakeholders   # Intervenants
POST   /immo/promo/projects/:id/stakeholders   # Ajouter un intervenant

# Permis
GET    /immo/promo/projects/:id/permits        # Permis du projet
POST   /immo/promo/projects/:id/permits        # Créer un permis

# Budget
GET    /immo/promo/projects/:id/budgets        # Budgets du projet
```

## 📊 Monitoring et Métriques

### Tableaux de Bord Disponibles

- **Dashboard Projet** : Vue d'ensemble avec KPI
- **Suivi Financier** : Analyse budgétaire et écarts
- **Planning** : Timeline et chemin critique
- **Intervenants** : Coordination et performance
- **Risques** : Matrice et plan d'action

### Métriques Clés

- Taux d'avancement global et par phase
- Respect des délais et alertes
- Écarts budgétaires et prévisions
- Performance des intervenants
- Statut des permis et autorisations

## 🚀 Évolutions et Roadmap

### Prochaines Fonctionnalités

- **IA et Machine Learning** : Prédiction des retards et optimisation
- **Intégrations** : APIs externes (cadastre, urbanisme)
- **Mobile** : Application mobile pour le suivi terrain
- **Reporting avancé** : Dashboards personnalisables
- **Workflows métier** : Automatisation des processus

### Améliorations en Cours

- Finalisation des services restants
- Optimisation des performances
- Tests système complets
- Documentation utilisateur

## 🔍 Dépannage

### Problèmes Courants

1. **Erreur de permissions**
   ```ruby
   # Vérifier les permissions utilisateur
   user.has_permission?('immo_promo:access')
   user.add_permission!('immo_promo:access')
   ```

2. **Problème de seeds**
   ```bash
   # Recréer l'environnement
   docker-compose run --rm web rails immo_promo:db:reseed
   ```

3. **Tests en échec**
   ```bash
   # Lancer les tests en mode debug
   docker-compose run --rm web bundle exec rspec engines/immo_promo/spec --format documentation
   ```

## 📚 Documentation

- **Guides utilisateur** : Workflows par profil
- **Documentation technique** : Architecture et APIs
- **Tests** : Couverture et stratégies
- **Déploiement** : Configuration production

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature
3. Implémenter les changements avec tests
4. Soumettre une Pull Request

## 📄 Licence

Module disponible sous licence MIT. Voir [MIT-LICENSE](MIT-LICENSE).

---

**ImmoPromo Engine** - Solution complète de gestion de projets immobiliers pour Docusphere
© 2024 - Développé avec ❤️ pour l'industrie immobilière