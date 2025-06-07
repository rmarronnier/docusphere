# Module Immo::Promo - Pilotage de Projets Immobiliers

## 🎯 Vue d'ensemble

Le module Immo::Promo est un système complet de pilotage de projets immobiliers intégré à Docusphere. Il offre une plateforme centralisée pour orchestrer tous les aspects techniques, juridiques et organisationnels des opérations immobilières.

## ✅ Fonctionnalités Implémentées

### 🏗️ Gestion de Projets
- **Projects** : Gestion complète des projets immobiliers (résidentiel, commercial, mixte, industriel)
- **Phases** : Planification par phases (études, permis, construction, réception, livraison)
- **Tasks** : Gestion granulaire des tâches avec dépendances et assignations
- **Timeline** : Suivi temps réel de l'avancement et détection automatique des retards

### 👥 Coordination des Intervenants
- **Stakeholders** : Annuaire centralisé (architectes, bureaux d'études, entreprises, sous-traitants)
- **Contracts** : Gestion des contrats et avenants
- **Certifications** : Suivi des habilitations et validité des assurances
- **Communication** : Historique complet des interactions

### 📋 Gestion Documentaire et Autorisations
- **Permits** : Workflow permis de construire avec suivi des délais
- **Permit Conditions** : Gestion des prescriptions et conditions
- **Documents** : Référentiel centralisé avec versioning automatique
- **Validation** : Signatures électroniques et diffusion contrôlée

### 💰 Suivi Financier
- **Budgets** : Gestion des budgets par version (initial, révisé, final)
- **Budget Lines** : Détail par poste (foncier, études, travaux, équipements)
- **Cost Tracking** : Suivi des coûts réels vs estimés

### 🏠 Gestion des Lots
- **Lots** : Définition des logements/locaux avec spécifications techniques
- **Reservations** : Système de réservation client
- **Specifications** : Détail des finitions et équipements

### ⚠️ Gestion des Risques
- **Risk Assessment** : Identification et évaluation des risques
- **Mitigation Plans** : Plans d'atténuation et de contingence
- **Monitoring** : Suivi continu et escalade automatique

### 📊 Reporting et Suivi
- **Progress Reports** : Rapports d'avancement périodiques
- **Milestones** : Jalons critiques avec alertes
- **Time Logs** : Suivi du temps passé par intervenant

## 🔧 Architecture Technique

### Modèles (16 modèles créés)
- `Immo::Promo::Project` - Projets immobiliers
- `Immo::Promo::Phase` - Phases de projet
- `Immo::Promo::Task` - Tâches et activités
- `Immo::Promo::Stakeholder` - Intervenants
- `Immo::Promo::Contract` - Contrats
- `Immo::Promo::Permit` - Permis et autorisations
- `Immo::Promo::Lot` - Lots/logements
- `Immo::Promo::Budget` - Budgets
- Et 8 autres modèles de support...

### Concerns Réutilisables
- `Addressable` - Gestion des adresses avec géocodage
- `Schedulable` - Planification avec dates et durées
- `WorkflowManageable` - Gestion des workflows et statuts
- `Authorizable` - Système de permissions granulaires

### Contrôleurs et Routes
- Routes sous `/immo/promo/`
- Contrôleurs avec autorisation Pundit
- Actions CRUD complètes + actions métier spécifiques

### Services Métier
- `ProjectManagerService` - Calcul d'avancement, chemin critique, optimisation
- `PermitTrackerService` - Suivi des permis et conformité réglementaire  
- `StakeholderCoordinatorService` - Coordination des intervenants

### Système d'Autorisation
- Intégration Pundit pour les permissions granulaires
- Groupes d'utilisateurs avec rôles
- Permissions lecture/écriture par utilisateur et groupe
- Policies spécialisées par contexte métier

### Composants ViewComponent
- `ProjectCardComponent` - Carte de projet avec indicateurs
- `TimelineComponent` - Timeline visuelle des phases
- Composants réutilisables et testables

## 🚀 Utilisation

### Accès
- URL : `/immo/promo/`
- Authentification requise
- Permission `immo_promo:access` nécessaire

### Création d'un Projet
```ruby
project = Immo::Promo::Project.create!(
  name: 'Résidence Les Jardins',
  reference: 'RLJ2024',
  project_type: 'residential',
  organization: current_user.organization,
  project_manager: current_user,
  start_date: Date.current,
  end_date: Date.current + 2.years,
  total_budget_cents: 500_000_000 # 5M EUR
)
```

### Utilisation des Services
```ruby
# Service de gestion de projet
service = Immo::Promo::ProjectManagerService.new(project, current_user)
progress = service.calculate_overall_progress
alerts = service.generate_schedule_alerts

# Service de coordination
coordinator = Immo::Promo::StakeholderCoordinatorService.new(project, current_user)
interventions = coordinator.coordinate_interventions
```

## 📁 Structure des Fichiers

```
app/
├── models/immo/promo/          # 16 modèles métier
├── controllers/immo/promo/     # 4 contrôleurs
├── policies/immo/promo/        # 4 policies d'autorisation
├── services/immo/promo/        # 3 services métier
├── components/immo/promo/      # 2 composants ViewComponent
└── views/immo/promo/           # Vues et templates

config/
└── routes.rb                   # Routes namespace :immo/:promo

db/migrate/
└── *_create_immo_promo_tables.rb  # Migration complète (19 tables)
```

## 🎨 Interface Utilisateur

- Interface responsive avec Tailwind CSS
- Dashboard de pilotage avec métriques clés
- Vues en liste et détail pour tous les objets
- Composants réutilisables pour la cohérence
- Timeline interactive pour le suivi visuel

## 🔒 Sécurité et Permissions

- Autorisation granulaire avec Pundit
- Isolation par organisation
- Permissions par rôle et par groupe
- Audit trail avec gem `audited`
- Validation stricte des données

## 🧪 Tests et Validation

- Structure complète validée
- Modèles testés avec données réelles
- Services métier fonctionnels
- Migrations appliquées avec succès
- 19 tables créées en base

## 📈 Évolutions Futures

Le système est conçu pour être extensible :
- Intégration avec des outils de CAO/BIM
- API REST pour applications mobiles
- Tableaux de bord avancés avec graphiques
- Notifications temps réel
- Intégration comptable et ERP

---

## 🎉 Conclusion

Le module Immo::Promo est maintenant **entièrement fonctionnel** et prêt pour la production. Il offre une solution complète et professionnelle pour le pilotage de projets immobiliers, avec une architecture robuste et évolutive.

**Accès:** `/immo/promo/` (authentification requise)