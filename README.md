# Docusphere - Plateforme de Gestion Documentaire et Immobilière

Docusphere est une application collaborative avancée de gestion documentaire développée avec Ruby on Rails, intégrant un module métier spécialisé pour l'immobilier. La plateforme combine une GED (Gestion Électronique de Documents) performante avec des outils métier spécialisés.

## 🚀 Quick Start

```bash
# First time setup
./bin/test setup

# Development workflow  
./bin/test quick --fix    # Before every commit
./bin/test ci --fix       # Before push/PR

# Start development
docker-compose up web
```

**Use `./bin/test` for ALL testing and validation - it's the unified, performant tool that replaces individual docker-compose and rspec commands.**

## 🎯 Vision Produit

Docusphere transforme la gestion documentaire traditionnelle en plateforme métier intelligente, avec un focus initial sur l'immobilier via le module **ImmoPromo**. L'objectif est de fournir une solution complète pour les professionnels nécessitant à la fois une GED robuste et des workflows métier spécialisés.

## ✨ Fonctionnalités Principales

### 📄 Gestion Documentaire Avancée
- **Formats supportés** : PDF, PDF/A, Word, Excel, PowerPoint, images, audio, vidéo, email, ZIP
- **Upload intelligent** : Glisser-déposer, import en lot, détection automatique de format
- **Traitement automatique** : OCR intégré (Tesseract), extraction de métadonnées, classification IA
- **Manipulation PDF** : Fusion, découpage, annotation, signature électronique
- **Versioning** : Gestion complète des versions avec historique et comparaison
- **Sécurité** : Chiffrement, filigrane, verrouillage, contrôle d'accès granulaire

### 🤝 Collaboration Moderne
- **Partage intelligent** : Liens sécurisés, permissions temporaires, traçabilité complète
- **Workflows** : Validation multi-niveaux, circuits d'approbation personnalisables
- **Notifications** : Système complet temps réel avec préférences utilisateur granulaires
- **Co-édition** : Édition collaborative type Office 365 avec synchronisation
- **Commentaires** : Annotations contextuelles, discussions par document

### 🗂️ Organisation Intelligente
- **Espaces thématiques** : Organisation par projet, département, ou domaine métier
- **Classification automatique** : IA pour catégorisation et métadonnées
- **Taxonomie flexible** : Plan de classement adaptatif, étiquettes intelligentes
- **Métadonnées** : Champs personnalisables avec héritage et templates
- **Relations** : Liens entre documents, projets et entités métier

### 🔍 Recherche & Découverte
- **Recherche intelligente** : Plein texte, métadonnées, contenu IA-indexé
- **Filtres dynamiques** : Interface intuitive avec suggestions automatiques
- **Recherches sauvegardées** : Alertes automatiques, rapports programmés
- **Découverte** : Recommandations basées sur l'usage et le contexte
- **Cross-référencement** : Liens automatiques entre documents similaires

### 👥 Administration Complète
- **Gestion utilisateurs** : SSO, LDAP, groupes dynamiques, déprovisioning automatique
- **Permissions granulaires** : Contrôle au niveau document, dossier, et fonctionnalité
- **Audit & conformité** : Logs détaillés, conformité RGPD, archivage légal
- **Analytiques** : Tableaux de bord usage, performance, ROI
- **Maintenance** : Monitoring proactif, optimisation automatique

## 🧪 Tests

**🚀 USE THE UNIFIED TEST SCRIPT `./bin/test` FOR ALL TESTING**

### Quick Testing Commands

```bash
# Before every commit
./bin/test quick --fix

# Full test suite
./bin/test ci --fix

# Specific test categories
./bin/test units              # Unit & integration tests
./bin/test system             # Browser tests with Selenium
./bin/test security           # Security scans
./bin/test lint --fix         # Code quality with auto-fix

# Diagnostics
./bin/test doctor            # Environment health check
```

### Advanced Testing

```bash
# Run specific RSpec file (when needed)
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb

# Debug system tests with visible browser
DEBUG=1 ./bin/test system

# Fast mode (skip slower tests)
./bin/test ci --fast --fix
```

The `./bin/test` script provides:
- Parallel test execution (4 processors)
- Auto-fix capabilities for common issues
- Clear progress reporting with timings
- Smart service management (starts Selenium, Redis, etc.)
- Consistent environment across all developers
- Handles ARM64 (Mac M1/M2) and x86_64 (Intel/CI) architectures
- Keeps services running after tests for debugging

View live browser during tests: `open http://localhost:7900`

## 🛣️ Route Validation & Development

### Automatic Route Validation

The project includes comprehensive route validation tools to prevent broken links and navigation issues:

```bash
# Full route audit
rake routes:audit

# Auto-fix ViewComponent route issues
rake routes:fix_common_issues

# Complete development setup with route validation
rake dev:setup

# Comprehensive validation (audit + tests)
rake dev:validate_routes
```

### Pre-commit Validation

```bash
# Manual pre-commit check
./bin/pre-commit

# Setup Git hooks (optional)
./bin/setup-git-hooks
```

### Route Development Guidelines

- ✅ **Never use hardcoded paths**: Use route helpers like `ged_document_path(doc)`
- ✅ **ViewComponents**: Always use `helpers.route_path` syntax  
- ✅ **Engine routes**: Use `engine_name.route_path` for cross-engine navigation
- ✅ **Assets**: Use `asset_path()` for static files

See [Route Guidelines](docs/DEVELOPMENT_ROUTE_GUIDELINES.md) for complete documentation.

### Automated Validation

- **GitHub Actions**: Automatic validation on every PR/push
- **CI/CD Integration**: Route validation integrated in test pipeline  
- **Auto-fix**: Common ViewComponent issues fixed automatically
- **Navigation Tests**: System tests validate all internal links

See `docs/SELENIUM_TESTING.md` for detailed testing documentation.

## 🏗️ Module ImmoPromo - Gestion Immobilière Intégrée

Docusphere intègre **ImmoPromo**, un module métier complet pour les professionnels de l'immobilier développé comme Rails Engine. Cette intégration transforme Docusphere en plateforme immobilière complète avec gestion documentaire centralisée.

### 🎯 Vue d'Ensemble ImmoPromo

**ImmoPromo** est conçu pour les promoteurs, maîtres d'ouvrage, architectes, et tous les acteurs de la chaîne immobilière nécessitant une coordination efficace et une traçabilité documentaire complète.

### 📋 Fonctionnalités Métier

#### 🏢 Gestion de Projets Immobiliers
- **Planification multi-phases** : De l'étude de faisabilité à la livraison
- **Timeline interactive** : Suivi visuel avec jalons et dépendances
- **Tableaux de bord** : KPIs temps réel, alertes proactives
- **Gestion des lots** : Définition, réservations, suivi commercial

#### 👥 Coordination des Intervenants  
- **Parties prenantes** : Architectes, bureaux d'études, entreprises, organismes
- **Gestion des contrats** : Centralisation, suivi échéances, pénalités
- **Certifications** : Suivi validité, alertes renouvellement
- **Planning partagé** : Coordination interventions, détection conflits

#### 📋 Workflow Permis & Autorisations
- **Permis de construire** : Guide étapes, checklist conformité
- **Autorisations** : Suivi conditions, dates limites, recours
- **Documents réglementaires** : Centralisation, versions, validations
- **Notifications** : Alertes échéances, rappels obligatoires

#### 💰 Suivi Financier Avancé
- **Budgets détaillés** : Postes, sous-postes, analyses d'écarts
- **Scénarios** : Optimiste/pessimiste, simulation impacts
- **Trésorerie** : Prévisionnels, besoins financement
- **Rentabilité** : ROI, TRI, seuils de rentabilité

#### ⚠️ Gestion des Risques
- **Identification** : Matrice risques/impacts/probabilités
- **Plans d'atténuation** : Actions préventives et correctives
- **Monitoring** : Suivi indicateurs, alertes précoces
- **Reporting** : Synthèses risques, recommandations

### 📄 Intégration Documentaire

#### 🔗 Documents Centralisés par Entité
- **Projets** : Cahiers des charges, études de faisabilité, bilans
- **Phases** : Rapports d'avancement, PV de réunions, validations
- **Tâches** : Devis, factures, comptes-rendus, livrables
- **Permis** : Dossiers complets, correspondances, modificatifs
- **Intervenants** : Contrats, assurances, certifications, CV

#### 📊 Workflows Documentaires Métier
- **Validation** : Circuits d'approbation spécialisés (technique, financier, juridique)
- **Versioning** : Gestion versions plans, cahiers des charges, contrats
- **Partage sélectif** : Documents par rôle et phase de projet
- **Archivage automatique** : Fin de phase, fin de projet, obligations légales

#### 🤖 Intelligence Documentaire
- **Classification automatique** : Reconnaissance type document (devis, facture, plan, etc.)
- **Extraction métadonnées** : Montants, dates, références, parties prenantes
- **Conformité** : Vérification présence documents obligatoires par phase
- **Alertes** : Documents manquants, échéances, validations en attente

### 🎨 Interfaces Spécialisées

#### 📊 Dashboard Coordination
- Vue d'ensemble interventions en cours
- Détection conflits planning et ressources  
- Suivi KPIs performance par intervenant
- Alertes retards et non-conformités

#### 💼 Dashboard Commercial
- Pipeline prospects et réservations
- Suivi disponibilités et tarification
- Statistiques ventes et rentabilité
- Gestion relation client intégrée

#### 📈 Dashboard Financier
- Analyse variance budget/réalisé en temps réel
- Prévisions trésorerie et besoins financement
- Scénarios et simulations économiques
- Reporting financier automatisé

#### ⚡ Dashboard Risques
- Matrice risques interactive avec drill-down
- Système d'alerte précoce configurable
- Suivi plans d'actions et efficacité
- Reporting conformité et audit

### 🛠️ Architecture Technique

#### 🧩 Rails Engine Modulaire
- **Isolation complète** : Modèles, contrôleurs, vues dédiés
- **API REST** : Endpoints spécialisés pour intégrations tierces
- **Événements** : Hooks pour synchronisation avec GED principale
- **Permissions** : Système d'autorisation unifié avec Docusphere

#### 🎨 Composants ViewComponent
- **Réutilisabilité** : Composants UI spécialisés métier immobilier
- **Cohérence** : Design system cohérent avec GED principale  
- **Performance** : Rendu optimisé et cache intelligent
- **Maintenance** : Séparation claire logique/présentation

#### 🔒 Sécurité & Conformité
- **Isolation données** : Cloisonnement par organisation/projet
- **Audit trail** : Traçabilité complète actions et accès
- **RGPD ready** : Gestion consentements et droit à l'oubli
- **Archivage légal** : Rétention documentaire selon obligations

### 🚀 Accès et Navigation

**URL d'accès** : `/immo/promo/`  
**Prérequis** : Authentification + permission `immo_promo:access`  
**Navigation** : Menu dédié dans barre principale Docusphere  
**Contexte** : Basculement fluide entre GED générale et module métier

## Prérequis

- Docker et Docker Compose
- 4GB de RAM minimum
- 10GB d'espace disque

## Installation

1. Cloner le repository
```bash
git clone [URL_DU_REPO]
cd docusphere
```

2. Lancer le script de configuration initiale
```bash
./setup.sh
# ou utiliser le script unifié
./bin/test setup
```

3. Démarrer l'application
```bash
docker-compose up
```

L'application sera accessible sur http://localhost:3000

**Compte administrateur par défaut :**
- Email : admin@docusphere.fr
- Mot de passe : password123

## 📁 Organisation du Projet

### Structure des Répertoires
```
docusphere/
├── app/                    # Application Rails principale
├── bin/                    # Scripts d'automatisation et utilitaires
│   ├── test               # Script unifié pour tous les tests
│   ├── setup-dev          # Configuration environnement développement
│   └── ...                # Autres scripts utilitaires
├── config/                 # Configuration Rails
├── db/                     # Base de données et migrations
├── docs/                   # Documentation détaillée du projet
│   ├── COMPONENTS_ARCHITECTURE.md
│   ├── PERFORMANCE_OPTIMIZATIONS.md
│   ├── SELENIUM_TESTING.md
│   └── ...                # Autres documentations techniques
├── engines/               
│   └── immo_promo/        # Module métier immobilier (Rails Engine)
├── spec/                   # Tests RSpec
└── storage/                # Stockage local des documents
```

### 📚 Documentation

**Documentation principale :**
- `README.md` - Ce fichier, vue d'ensemble du projet
- `CLAUDE.md` - Instructions pour l'assistant IA et pièges connus
- `WORKFLOW.md` - Procédures obligatoires pour éviter les régressions

**Documentation technique (dans `docs/`) :**
- Architecture des composants, stratégies de test
- Guides de performance, configuration Selenium
- Plans de stabilisation, status du projet
- Documentation complète des modèles et workflows

## 🏗️ Architecture Technique

### 💻 Stack Technologique
- **Backend** : Ruby on Rails 7.1+ avec architecture modulaire
- **Frontend** : ViewComponent + Turbo + Stimulus + Tailwind CSS
- **Base de données** : PostgreSQL 15 avec extensions (pgcrypto, uuid, full-text search)
- **Cache & Queues** : Redis pour sessions, cache, et Sidekiq
- **Recherche** : Elasticsearch 8.x avec indexation automatique
- **Stockage** : Active Storage + traitement d'images/documents
- **JavaScript Runtime** : Bun (remplacement de Node.js) pour rapidité et efficacité
- **Tests JavaScript** : Bun test runner avec JSDOM pour les tests Stimulus
- **Monitoring** : Logs structurés, métriques application
- **Tests visuels** : Lookbook pour prévisualisation des composants

### 🧩 Architecture Modulaire
- **Core GED** : Fonctionnalités documentaires de base
- **Rails Engines** : Modules métier isolés (ImmoPromo, futurs modules)
- **ViewComponents** : Composants UI réutilisables avec architecture modulaire (DataGrid, Actions, etc.)
- **Service Objects** : Logique métier centralisée et testable
- **API REST** : Endpoints versionnés pour intégrations tierces

### 🔄 Patterns & Conventions
- **SOLID principles** : Code maintenable et extensible
- **Convention over configuration** : Réduction complexité développement
- **Domain-Driven Design** : Modélisation métier claire
- **Event-driven architecture** : Communication inter-modules via événements
- **Test-driven development** : Couverture tests complète (>90%)

## Services Docker

- `web` : Application Rails (port 3000)
- `db` : PostgreSQL (port 5432)
- `redis` : Redis (port 6379)
- `sidekiq` : Worker Sidekiq
- `elasticsearch` : Moteur de recherche (port 9200)
- `selenium` : Tests système avec navigateur (port 7900 pour VNC)

## Développement

### 🛠️ Commandes de Développement

#### Tests & Qualité
```bash
# Tests parallèles (recommandé)
docker-compose run --rm -e PARALLEL_TEST_PROCESSORS=4 web bundle exec parallel_rspec

# Tests séquentiels avec fail-fast
docker-compose run --rm web bundle exec rspec --fail-fast

# Tests spécifiques
docker-compose run --rm web bundle exec rspec spec/models/
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/

# Qualité code
docker-compose run --rm web bundle exec rubocop
docker-compose run --rm web bundle exec brakeman
```

#### Administration
```bash
# Console Rails
docker-compose run --rm web rails console

# Migrations
docker-compose run --rm web rails db:migrate
docker-compose run --rm web rails immo_promo:install:migrations

# Seed data
docker-compose run --rm web rails db:seed

# Monitoring
docker-compose logs -f web
docker-compose logs -f sidekiq
```

#### Développement
```bash
# Reconstruire images
docker-compose build

# Reset complet environnement
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

### 📁 Structure du Projet

```
docusphere/                         # 🏠 Racine application
├── 📱 app/                         # Application principale
│   ├── 🗃️  models/                # Modèles métier (Document, User, etc.)
│   ├── 🎮 controllers/            # Contrôleurs REST & API
│   ├── 🎨 views/                  # Templates ERB
│   ├── 🧩 components/             # ViewComponents réutilisables
│   ├── 🔧 services/               # Logique métier (NotificationService, etc.)
│   ├── 🛡️  policies/              # Autorisations Pundit
│   ├── ⚡ javascript/             # Stimulus controllers
│   └── 💼 jobs/                   # Jobs asynchrones Sidekiq
├── ⚙️  config/                     # Configuration Rails
│   ├── 🌐 locales/                # Internationalisation (FR/EN)
│   ├── 🗃️  database.yml           # Configuration PostgreSQL
│   └── 🚀 initializers/          # Configuration gems & services
├── 🗃️  db/                        # Base de données
│   ├── 📋 migrate/                # Migrations consolidées (8 fichiers)
│   └── 🌱 seeds.rb                # Données d'exemple
├── 🏗️  engines/                   # Modules métier Rails Engine
│   └── 🏠 immo_promo/             # Module immobilier
│       ├── 📱 app/                # MVC spécialisé immobilier
│       │   ├── 🗃️  models/        # Projets, Phases, Tâches, etc.
│       │   ├── 🎮 controllers/    # API & interfaces métier
│       │   ├── 🧩 components/     # UI spécialisée immobilier
│       │   └── 🛡️  policies/      # Permissions métier
│       ├── ⚙️  config/            # Routes & configuration engine
│       ├── 🗃️  db/                # Migrations engine
│       └── 🧪 spec/               # Tests engine (>95% couverture)
├── 🧪 spec/                       # Tests application principale
│   ├── 📋 models/                # Tests modèles
│   ├── 🎮 controllers/           # Tests contrôleurs
│   ├── 🧩 components/            # Tests ViewComponents
│   ├── 🌐 system/                # Tests end-to-end
│   └── 🏭 factories/             # Données de test FactoryBot
├── 📄 storage/                    # Documents & fichiers
│   └── 📂 sample_documents/      # Documents d'exemple immobilier
├── 🐳 docker-compose.yml         # Orchestration services Docker
└── 📚 README.md                  # Documentation projet
```

### 🧪 Couverture Tests

- **Application principale** : >90% couverture
- **Engine ImmoPromo** : >95% couverture  
- **Types de tests** : Unit, Integration, System, Component, JavaScript
- **Tools Ruby** : RSpec, FactoryBot, Capybara, Selenium
- **Tools JavaScript** : Bun test runner, JSDOM pour tests Stimulus controllers
- **Architecture tests** : Tests parallèles (4 processeurs), fail-fast, auto-fix

### 📊 Métriques Qualité

- **Complexité cyclomatique** : < 15 par méthode
- **Duplication** : < 5% code dupliqué
- **Sécurité** : Scan Brakeman sans vulnérabilités critiques
- **Performance** : Temps réponse < 200ms P95

## 📄 Licence

**Propriétaire** - Tous droits réservés  
© 2025 DocuSphere - Plateforme de Gestion Documentaire Métier