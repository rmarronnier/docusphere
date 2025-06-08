# ImmoPromo - Module de Gestion de Projets Immobiliers

ImmoPromo est un engine Rails offrant une solution complète de pilotage de projets immobiliers pour Docusphere. Il permet d'orchestrer tous les aspects techniques, juridiques et organisationnels des opérations immobilières.

## Description

Ce module fournit un système complet de gestion de projets immobiliers couvrant l'intégralité du cycle de vie d'un projet : de la conception à la livraison, en passant par les autorisations administratives, la construction et la commercialisation.

## 🚀 Nouveautés - Interfaces Métier

ImmoPromo propose désormais des **interfaces métier spécialisées** qui vont au-delà de la simple gestion CRUD pour offrir des workflows adaptés aux besoins réels des professionnels de l'immobilier.

### 🎯 Tableaux de Bord Spécialisés

#### 1. **Coordination des Intervenants** (`/projects/:id/coordination`)
- Dashboard temps réel des interventions en cours
- Détection automatique des conflits de ressources
- Suivi de conformité des certifications
- Analyse de performance des équipes
- Recommandations d'optimisation IA

#### 2. **Workflow Permis & Autorisations** (`/projects/:id/permit_workflow`)
- Guide workflow adapté au type de projet
- Checklist de conformité réglementaire
- Timeline avec chemin critique
- Intégration administrative (soumission, suivi, relances)
- Générateur de dossiers de soumission

#### 3. **Dashboard Financier** (`/projects/:id/financial`)
- Analyse de variance en temps réel
- Contrôle des coûts avec détection d'anomalies
- Gestion de trésorerie et prévisions
- Scénarios budgétaires (optimiste/pessimiste/stress test)
- Analyse de rentabilité

#### 4. **Interface Commerciale** (`/projects/:id/commercial`)
- Gestion d'inventaire des lots avec filtres avancés
- Pipeline de réservations et conversions
- Stratégie de tarification dynamique
- Analyse des performances commerciales
- Insights clients et segmentation

#### 5. **Monitoring des Risques** (`/projects/:id/risk-monitoring`)
- Matrice des risques interactive
- Système d'alerte précoce (Early Warning)
- Suivi des plans d'atténuation
- Escalade automatique des risques critiques
- Analyse prédictive des tendances

### 🧩 Composants Réutilisables

ImmoPromo intègre des composants modulaires factorisés pour garantir une interface cohérente :

- **MetricCardComponent** : Cartes de métriques avec icônes et valeurs
- **AlertBannerComponent** : Bannières d'alertes contextuelles
- **StatusBadgeComponent** : Badges de statut standardisés
- **ProgressIndicatorComponent** : Barres de progression unifiées
- **ActionButtonComponent** : Boutons d'action cohérents
- **DataTableComponent** : Tables de données réutilisables

Ces composants s'intègrent parfaitement avec les composants existants de l'application principale.

## Fonctionnalités Principales

### 🏗️ Gestion de Projets
- **Types de projets supportés** : Résidentiel, commercial, mixte, industriel
- **Planification par phases** : Études, permis, construction, réception, livraison
- **Suivi en temps réel** : Timeline interactive avec détection automatique des retards
- **Dashboard centralisé** : Vue d'ensemble avec métriques clés et alertes

### 📋 Gestion des Tâches
- **Création et assignation** : Tâches granulaires avec responsables désignés
- **Dépendances** : Gestion des prérequis et enchaînements
- **Suivi d'avancement** : Pourcentage de completion et temps passé
- **Alertes automatiques** : Notifications sur les retards et échéances

### 👥 Coordination des Intervenants
- **Annuaire centralisé** : Architectes, bureaux d'études, entreprises, sous-traitants
- **Gestion des contrats** : Suivi des contrats et avenants
- **Certifications** : Contrôle des habilitations et validité des assurances
- **Historique** : Traçabilité complète des interactions

### 📑 Permis et Autorisations
- **Workflow intégré** : Gestion du processus de permis de construire
- **Suivi des conditions** : Gestion des prescriptions et réserves
- **Alertes réglementaires** : Rappels des échéances administratives
- **Documents associés** : Centralisation des pièces justificatives

### 💰 Suivi Financier
- **Budgets multi-versions** : Initial, révisé, final
- **Ventilation par postes** : Foncier, études, travaux, équipements, honoraires
- **Analyse des écarts** : Comparaison prévisionnel/réel
- **Reporting financier** : Tableaux de bord et exports

### 🏠 Gestion des Lots
- **Définition technique** : Surfaces, typologie, orientation
- **Spécifications** : Finitions et équipements par lot
- **Réservations** : Système complet de gestion commerciale
- **Statuts** : Disponible, réservé, vendu

### ⚠️ Gestion des Risques
- **Identification** : Catalogue de risques types
- **Évaluation** : Probabilité et impact
- **Plans d'action** : Mesures d'atténuation et contingence
- **Suivi** : Monitoring continu avec escalade

## Structure du Module

### Modèles de Données

```ruby
# Modèles principaux
Immo::Promo::Project       # Projets immobiliers
Immo::Promo::Phase         # Phases du projet
Immo::Promo::Task          # Tâches détaillées
Immo::Promo::Stakeholder   # Parties prenantes
Immo::Promo::Permit        # Permis et autorisations
Immo::Promo::Budget        # Budgets
Immo::Promo::Lot           # Lots/logements
Immo::Promo::Risk          # Risques

# Modèles de support
Immo::Promo::Contract      # Contrats
Immo::Promo::Certification # Certifications
Immo::Promo::Reservation   # Réservations
Immo::Promo::Milestone     # Jalons
Immo::Promo::TimeLog       # Temps passé
# ... et autres
```

### Services Métier

```ruby
# Gestion de projet
Immo::Promo::ProjectManagerService
- calculate_overall_progress      # Calcul de l'avancement global
- calculate_critical_path         # Identification du chemin critique
- generate_schedule_alerts        # Génération des alertes planning
- optimize_resource_allocation    # Optimisation des ressources

# Suivi des permis
Immo::Promo::PermitTrackerService
- check_permit_status            # Vérification des statuts
- generate_renewal_alerts        # Alertes de renouvellement
- check_compliance              # Conformité réglementaire

# Coordination
Immo::Promo::StakeholderCoordinatorService
- coordinate_interventions       # Planification des interventions
- check_certifications          # Vérification des habilitations
- generate_coordination_report   # Rapports de coordination
```

### API Endpoints

Le module expose une API REST complète sous `/immo/promo/` :

```
# Projets
GET    /projects                    # Liste des projets
POST   /projects                    # Créer un projet
GET    /projects/:id                # Détails d'un projet
GET    /projects/:id/dashboard      # Dashboard du projet
PUT    /projects/:id                # Mettre à jour un projet
DELETE /projects/:id                # Supprimer un projet

# Phases
GET    /projects/:project_id/phases
POST   /projects/:project_id/phases
GET    /projects/:project_id/phases/:id
PUT    /projects/:project_id/phases/:id
DELETE /projects/:project_id/phases/:id

# Tâches
GET    /projects/:project_id/phases/:phase_id/tasks
POST   /projects/:project_id/phases/:phase_id/tasks
GET    /projects/:project_id/phases/:phase_id/tasks/:id
GET    /projects/:project_id/phases/:phase_id/tasks/:id/my_tasks
PUT    /projects/:project_id/phases/:phase_id/tasks/:id
DELETE /projects/:project_id/phases/:phase_id/tasks/:id

# Autres ressources suivent le même pattern RESTful
# (stakeholders, permits, budgets, contracts, lots, risks, etc.)
```

## Installation

### 1. Ajouter l'engine au Gemfile

```ruby
gem 'immo_promo', path: 'engines/immo_promo'
```

### 2. Installer les dépendances

```bash
docker-compose run --rm web bundle install
```

### 3. Monter l'engine dans routes.rb

```ruby
mount ImmoPromo::Engine => "/immo/promo"
```

### 4. Exécuter les migrations

```bash
docker-compose run --rm web rails immo_promo:install:migrations
docker-compose run --rm web rails db:migrate
```

### 5. Configurer les permissions

Ajouter la permission `immo_promo:access` aux utilisateurs concernés.

## Tests

### Exécuter tous les tests du module

```bash
# Tests en parallèle (recommandé)
docker-compose run --rm -e PARALLEL_TEST_PROCESSORS=4 web bundle exec parallel_rspec engines/immo_promo/spec

# Tests séquentiels
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec
```

### Tests spécifiques

```bash
# Tests des modèles
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/models

# Tests des contrôleurs
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/controllers

# Tests des services
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/services

# Tests d'intégration
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/integration
```

## Configuration

### Initializer

Créer un fichier `config/initializers/immo_promo.rb` :

```ruby
ImmoPromo.configure do |config|
  # Configuration des types de projets autorisés
  config.project_types = %w[residential commercial mixed industrial]
  
  # Configuration des phases par défaut
  config.default_phases = %w[studies permits construction reception delivery]
  
  # Configuration des alertes
  config.alert_days_before_deadline = 7
  config.permit_renewal_alert_days = 30
  
  # Configuration des permissions
  config.require_approval_for_budget_changes = true
end
```

## Utilisation

### Création d'un projet

```ruby
project = Immo::Promo::Project.create!(
  name: "Résidence Les Jardins",
  reference: "RLJ2024",
  project_type: "residential",
  organization: current_organization,
  project_manager: current_user,
  start_date: Date.current,
  end_date: Date.current + 2.years,
  total_budget_cents: 500_000_000, # 5M EUR
  description: "Construction de 50 logements avec espaces verts",
  address: "123 rue Example, 75001 Paris",
  total_area_sqm: 4500,
  units_count: 50
)
```

### Ajout de phases

```ruby
phase = project.phases.create!(
  name: "Phase Études",
  phase_type: "studies",
  start_date: Date.current,
  end_date: Date.current + 3.months,
  responsible: architect_user,
  budget_cents: 50_000_000 # 500k EUR
)
```

### Création de tâches

```ruby
task = phase.tasks.create!(
  name: "Étude de sol",
  description: "Analyse géotechnique du terrain",
  assigned_to: geotechnical_engineer,
  start_date: Date.current,
  due_date: Date.current + 2.weeks,
  priority: "high",
  estimated_hours: 40
)
```

### Utilisation des services

```ruby
# Service de gestion de projet
service = Immo::Promo::ProjectManagerService.new(project, current_user)
progress = service.calculate_overall_progress
alerts = service.generate_schedule_alerts
critical_path = service.calculate_critical_path

# Service de suivi des permis
permit_service = Immo::Promo::PermitTrackerService.new(project, current_user)
permit_status = permit_service.check_permit_status
compliance = permit_service.check_compliance

# Service de coordination
coordinator = Immo::Promo::StakeholderCoordinatorService.new(project, current_user)
interventions = coordinator.coordinate_interventions
report = coordinator.generate_coordination_report
```

## Sécurité et Permissions

Le module utilise Pundit pour la gestion des autorisations :

- **Isolation par organisation** : Les utilisateurs ne voient que les projets de leur organisation
- **Permissions granulaires** : Lecture/écriture par utilisateur et groupe
- **Rôles prédéfinis** : project_manager, stakeholder, viewer
- **Audit trail** : Toutes les modifications sont tracées via la gem `audited`

### Exemple de policy

```ruby
class Immo::Promo::ProjectPolicy < ApplicationPolicy
  def index?
    user.has_permission?('immo_promo:access')
  end

  def show?
    user.has_permission?('immo_promo:access') && 
    (record.organization == user.organization || record.stakeholders.include?(user))
  end

  def create?
    user.has_permission?('immo_promo:manage_projects')
  end

  def update?
    user == record.project_manager || user.has_permission?('immo_promo:manage_projects')
  end
end
```

## Dépannage

### Problèmes courants

1. **Erreur de permissions**
   - Vérifier que l'utilisateur a la permission `immo_promo:access`
   - Vérifier l'appartenance à l'organisation du projet

2. **Erreur de migration**
   - S'assurer que toutes les migrations sont exécutées
   - Vérifier la présence de la migration `create_immo_promo_tables.rb`

3. **Routes non trouvées**
   - Vérifier que l'engine est bien monté dans `routes.rb`
   - Redémarrer le serveur après modification

## Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amazing-feature`)
3. Commiter les changements (`git commit -m 'Add amazing feature'`)
4. Pousser la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

## Licence

Ce module est disponible sous licence MIT. Voir le fichier [MIT-LICENSE](MIT-LICENSE) pour plus de détails.

## Support

Pour toute question ou problème :
- Ouvrir une issue sur le repository
- Contacter l'équipe de développement
- Consulter la documentation complète dans `/docs/immo_promo/`

---

© 2024 Docusphere - Module ImmoPromo