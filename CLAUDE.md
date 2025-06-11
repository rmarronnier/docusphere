# CLAUDE.md - AI Assistant Instructions

## 🚨 OBLIGATOIRE : Lire WORKFLOW.md avant TOUTE session

Ce fichier contient les procédures obligatoires pour éviter les régressions. **NE PAS** commencer une session sans avoir lu et compris WORKFLOW.md.

## Important Rules

**NEVER run git commands directly**. Always let the user handle git operations.

**⚠️ DOCUMENT VERSIONING**: Document model uses PaperTrail for versioning with a custom DocumentVersion class that inherits from PaperTrail::Version. This provides document-specific versioning features while leveraging PaperTrail's robust infrastructure. Access versions through `document.versions` which returns DocumentVersion instances.

**🚨 RÈGLE FONDAMENTALE DE DÉVELOPPEMENT**: Si on crée ou on touche à du code (Ruby, JavaScript, CSS, etc.), alors on DOIT immédiatement :
1. Écrire ou mettre à jour les tests associés
2. Lancer les tests pour vérifier qu'ils passent
3. Corriger les erreurs si nécessaire
4. Ne considérer la tâche comme terminée QUE quand tous les tests passent

Cette règle s'applique à TOUT le code : composants, services, contrôleurs, modèles, JavaScript, etc.

**🚨 RÈGLE FONDAMENTALE DES TESTS**: Si un test teste une méthode non existante :
1. **NE JAMAIS** supprimer le test
2. **TOUJOURS** faire une réflexion métier pour comprendre pourquoi cette méthode devrait exister
3. **IMPLÉMENTER** la méthode manquante dans le service/contrôleur/modèle testé
4. Cette règle garantit que les tests documentent le comportement attendu du système

**📝 RÈGLE DE DOCUMENTATION AUTOMATIQUE**: Après CHAQUE tâche TODO complétée :
1. Mettre à jour `docs/PROJECT_STATUS.md` avec les changements réalisés
2. Mettre à jour `docs/TODO.md` pour marquer la tâche comme complétée (✅)
3. Si la tâche est entièrement terminée, la déplacer vers `docs/archive/DONE.md`
4. Cette mise à jour DOIT être faite immédiatement après la complétion de la tâche

**🛣️ RÈGLE FONDAMENTALE DES ROUTES**: Pour éviter les liens brisés et erreurs de navigation :
1. **JAMAIS de chemins hardcodés** : Utiliser `ged_document_path(doc)` au lieu de `"/ged/documents/1"`
2. **ViewComponents** : Toujours `helpers.route_path` au lieu de `route_path` direct
3. **Engines** : Utiliser `immo_promo_engine.projects_path` pour naviguer vers les engines
4. **Assets** : Utiliser `asset_path()` pour tous les fichiers statiques
5. **Validation automatique** : Lancer `rake routes:audit` avant chaque commit
6. **Auto-correction** : Utiliser `rake routes:fix_common_issues` pour corriger les ViewComponents

## ⚠️ Pièges Connus (Mis à jour 10/06/2025)

1. **Document#lock!** : Override la méthode PaperTrail - cause un warning au démarrage
2. **Authorizable#owned_by?** : Vérifie différents attributs selon le modèle (user, uploaded_by, project_manager)
3. **WorkflowManageable** : Incompatible avec Workflow model (utilise des statuts différents)
4. **Tests parallèles** : Maintenant utilisés en CI avec parallel_rspec et 4 processeurs
5. **Factories avec associations** : Toujours vérifier le schema.rb pour les colonnes réelles
6. **ValidationRequest polymorphic** : Utiliser `validatable:` au lieu de `document:` dans les tests/factories
7. **Engine DocumentPolicy** : Supprimé - utiliser la policy principale via le concern Documentable
8. **Tags nécessitent organization** : Tous les tags doivent avoir une organization lors de la création
9. **Enum validations** : Pour les enums, ajouter `validates :field, presence: true` si requis
10. **Controller templates** : Utiliser `format: :json` dans les tests si les templates manquent
11. **SearchQuery.recent** : Scope filtre par date (30 jours), pas seulement ordre chronologique

## GitHub Actions Compatibility

When running on GitHub Actions (x86_64-linux), you may need to add the platform to Gemfile.lock:
```bash
docker-compose run --rm web bundle lock --add-platform x86_64-linux
```

### GitHub Actions Improvements (June 10, 2025)

**CI/CD Pipeline Optimizations:**
- **Parallel Testing**: Now uses `parallel_rspec` with 4 processors for faster test execution
- **System Tests**: Added Selenium service with proper health checks and environment variables
- **Caching**: Implemented Bun dependency caching across all jobs for better performance
- **Timeouts**: Added appropriate timeouts to prevent hanging jobs (10-45 minutes)
- **Permissions**: Added proper permissions for security events and content access
- **Artifact Management**: Updated to upload-artifact@v4 with retention policies and failure artifacts
- **Test Separation**: Separate execution of unit tests and system tests for better reliability

**Dependabot Configuration Improvements:**
- **Scheduling**: Optimized to weekly intervals with timezone support (Europe/Paris)
- **Grouping**: Logical grouping of dependencies (Rails, testing, security, frontend, etc.)
- **Engine Support**: Added support for Immo::Promo engine dependencies
- **Multiple Ecosystems**: Support for Bundler, NPM, GitHub Actions, and Docker
- **Commit Messages**: Structured commit message prefixes for better organization
- **Review Limits**: Reduced PR limits to manageable numbers (3-5 per ecosystem)

### Universal Test Runner (June 10, 2025)

**🚀 ONE SCRIPT TO RULE THEM ALL: `./bin/test`**

**This is THE primary tool for all testing and validation. Use it instead of individual docker-compose or rspec commands for consistent, fast, and reliable results.**

**Commands:**
- `quick` - Fast pre-commit checks (lint + sample tests)
- `security` - Security scans (Brakeman, Bundle Audit, Bun Audit)  
- `lint` - Code quality (RuboCop, ESLint, Stylelint)
- `units` - Unit & integration tests (parallel execution)
- `engine` - Engine tests (Immo::Promo module)
- `system` - Browser integration tests (Selenium)
- `ci` - Complete CI/CD simulation
- `all` - Everything including diagnostics
- `doctor` - Environment diagnostics
- `setup` - Initial development environment setup

**Options:**
- `--fix` - Auto-fix issues when possible
- `--fast` - Skip slower operations
- `--quiet` - Minimal output
- `--verbose` - Detailed debug output

**Performance Features:**
- Parallel test execution (4 processors)
- Concurrent security scans  
- Smart test environment detection
- Detailed timing and progress reporting
- Auto-fix capabilities for common issues

**Recommended Usage (USE THESE):**
```bash
# 🔥 MOST COMMON - Development workflow
./bin/test quick --fix           # Before every commit

# 🚀 COMPLETE - Before push/PR
./bin/test ci --fix              # Full CI simulation

# ⚡ FAST - Quick feedback
./bin/test ci --fast --fix       # Skip system tests

# 🩺 DEBUG - When things break
./bin/test doctor --verbose      # Diagnose issues

# 🏗️ SETUP - First time only
./bin/test setup                 # Environment setup
```

**Legacy scripts (prefer ./bin/test):**
- `./bin/pre-ci` ← Use `./bin/test ci` instead
- `./bin/quick-check` ← Use `./bin/test quick` instead  
- `./bin/ci-doctor` ← Use `./bin/test doctor` instead

## Recent Changes (June 10, 2025)

### Repository Cleanup
- **Root directory cleaned**: Moved 11 scripts to `bin/` directory
- **Documentation organized**: Moved 10 .md files to `docs/` directory  
- **Temporary files removed**: Deleted old test outputs and backup files
- **Screenshots cleaned**: Removed old failure screenshots from `tmp/screenshots/`
- **Result**: Root directory now contains only essential configuration files

## Recent Changes (June 10, 2025)

### 1. Test Suite Stabilization Complete ✅
- **Phase 1.3 ✅**: All non-system tests now passing (1463+ tests across both app and engine)
- **Models**: 277 tests passing - Fixed SearchQuery scope, MetadataTemplate methods, WorkflowStep associations
- **Policies**: 150+ tests passing - Fixed authorization flows and Pundit integration  
- **Controllers**: 219+ tests passing - Fixed authorization and template issues
- **Services**: 50+ tests passing - Fixed private method calls and data dependencies
- **Components**: 970+ tests passing (899 app + 71 engine) - All ViewComponent tests stable

### 2. Engine Integration Fixes
- **DocumentPolicy Cleanup**: Removed obsolete engine DocumentPolicy, using main app policy via Documentable concern
- **Component Updates**: Updated DocumentListComponent to use Pundit helpers `policy()` syntax
- **Missing Methods**: Added `allocate?` and `qualify?` methods to StakeholderPolicy
- **Template Issues**: Fixed controller tests to use JSON format when templates missing

### 3. Key Bug Fixes Applied
- **DocumentProcessingService**: Fixed tag creation to include organization requirement
- **AiClassificationService**: Fixed private method access and entity extraction format
- **ValidationRequest**: Standardized polymorphic association from `document:` to `validatable:`
- **PermitCondition**: Added required validation for `condition_type` enum
- **UserPolicy**: Fixed security issue preventing cross-organization access
- **NotificationService**: Replaced mocks with real ValidationRequest objects

### 4. ViewComponent Architecture Refactoring
- **DataGridComponent** refactorisé en 5 sous-composants modulaires :
  - `ColumnComponent` : Configuration des colonnes
  - `CellComponent` : Rendu et formatage des cellules  
  - `HeaderCellComponent` : En-têtes avec tri
  - `ActionComponent` : Actions flexibles (inline/dropdown/buttons)
  - `EmptyStateComponent` : États vides personnalisables
- Tests complets pour tous les composants (102 tests passants)
- Architecture facilitant la réutilisation et la maintenance

### 5. Documentation Visual Testing
- Création de `VISUAL_TESTING_SETUP.md` avec stratégies pour feedback visuel
- Script `bin/capture-ui-components` pour screenshots automatiques
- Plan d'intégration de Lookbook pour prévisualisation des composants

## Recent Changes (June 2025)

### 1. Selenium Testing Infrastructure
- Added dedicated Selenium service in Docker Compose
- Supports both ARM64 (Mac M1/M2) and x86_64 (GitHub Actions)
- Centralized Capybara configuration with automatic Docker detection
- Created SystemTestHelper for common test functionality
- Script `bin/system-test` for easy test execution
- Full documentation in `docs/SELENIUM_TESTING.md`

### 2. Test Stabilization Progress
- **Phase 1.1 ✅**: All controller tests passing (251 examples)
- **Phase 1.2 ✅**: System test infrastructure ready
- Fixed Pundit authorization issues across multiple controllers
- Created missing policies (ValidationRequestPolicy, DocumentValidationPolicy)
- Fixed Tag model validation order (before_validation for normalization)
- Removed non-existent UserNotificationPreference model/controller

### 3. Key Lessons Learned
- **Always check schema.rb** before creating models/factories
- **Pundit action inference**: `create_space` action looks for `create_space?` method
- **Callback order matters**: Use `before_validation` for data normalization
- **UI has changed significantly**: Many system tests need updating

## Recent Changes (January 2025)

### 1. Database Consolidation
The database migrations have been consolidated from 44 files down to 8 comprehensive migration files:
- 001_create_core_system.rb - Core system tables (organizations, users, notifications, audited)
- 002_create_document_system.rb - Document management system
- 003_create_authorization_system.rb - User groups and authorization
- 004_create_metadata_system.rb - Metadata system
- 005_create_workflow_system.rb - Workflow system
- 006_create_validation_system.rb - Validation system
- 007_create_auxiliary_features.rb - Auxiliary features (baskets, links, etc.)
- 008_create_immo_promo_module.rb - Immo Promo module (now in engine)

### 2. New Concerns Created
Four new concerns have been added to enhance modularity:
- **Validatable** - Adds validation workflow capabilities to models
- **Uploadable** - Adds file upload capabilities to models
- **Storable** - Manages storage location and organization
- **Linkable** - Adds linking capabilities between models

### 3. Immo::Promo Converted to Rails Engine
The Immo::Promo module has been converted to a Rails engine located at `engines/immo_promo/`:
- All models, controllers, views, services, and policies moved to the engine
- Engine is mounted at `/immo/promo` in the main application
- Engine has its own gemspec, routes, and migration
- To run engine migrations: `rails immo_promo:install:migrations && rails db:migrate`

### 4. Seed Data Optimization
- Document creation reduced from 5000 to 300 for faster seeding
- Fixed authorization uniqueness constraints using find_or_create_by

## Testing Requirements

**IMPORTANT**: 
- **DO NOT use parallel tests in GitHub Actions** - Use standard `bundle exec rspec` instead
- Parallel tests are only for local development

For every new feature or functionality added to the codebase, you MUST:
1. Write corresponding RSpec tests (unit tests, integration tests, or system tests as appropriate)
2. Ensure tests cover both happy paths and edge cases
3. Run tests to verify they pass before considering the feature complete
4. Follow existing test patterns and conventions in the codebase
5. Update GitHub Actions workflows (.github/workflows/) if new dependencies or test configurations are needed

### System Tests (Selenium Setup)

**🚨 IMPORTANT: ALWAYS use the `bin/system-test` script for running system tests**

System tests use Chromium with Selenium WebDriver in headless mode. The configuration is set up in `spec/support/capybara.rb`:

- **Driver**: Remote Selenium Chrome in headless mode
- **Browser options**: Configured for Docker environment with `--no-sandbox`, `--disable-dev-shm-usage`
- **Screenshots**: Automatically saved to `tmp/screenshots/` when tests fail
- **VNC Access**: View live browser at http://localhost:7900 for debugging

**Running System Tests**:
```bash
# ✅ CORRECT - Always use the script
./bin/system-test

# ✅ Run specific system test
./bin/system-test spec/system/document_upload_workflow_spec.rb

# ✅ Run with options
./bin/system-test --fail-fast

# ✅ Run engine system tests
./bin/system-test engines/immo_promo/spec/system/

# ❌ WRONG - Do not use plain docker-compose commands
# docker-compose run --rm web bundle exec rspec spec/system/
```

**Why use the script?**
- Ensures Selenium service is running
- Waits for all services to be ready
- Sets up test database correctly
- Configures proper Docker networking
- Handles architecture detection (ARM64 vs x86_64)

**Debugging**:
- View live browser: `open http://localhost:7900`
- Use `debug: true` metadata to run tests with visible browser
- Set `DEBUG=1` environment variable to pause tests

See `docs/SELENIUM_TESTING.md` for detailed documentation.

## Running Ruby Commands

All Ruby-dependent commands (such as `rspec`, `bundle`, `rails`, etc.) should be run inside a Docker container. Use the following patterns:

### Running Tests

#### Initial Setup for Parallel Tests
```bash
# First time setup - create parallel test databases
./bin/parallel_test_setup
```

#### Running Tests
```bash
# Run tests in parallel (RECOMMENDED - faster, default for CI)
docker-compose run --rm -e PARALLEL_TEST_PROCESSORS=4 web bundle exec parallel_rspec

# Run tests in parallel with fail-fast
docker-compose run --rm -e PARALLEL_TEST_PROCESSORS=4 web bundle exec parallel_rspec --fail-fast

# Run tests sequentially with fail-fast to quickly identify first failure
docker-compose run --rm web bundle exec rspec --fail-fast

# Run full test suite sequentially
docker-compose run --rm web bundle exec rspec --format progress

# Run specific test file
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb

# Run specific test by line number
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb:42
```

Note: 
- Parallel tests use 4 processors by default to avoid database connection issues
- Test databases: docusphere_test, docusphere_test2, docusphere_test3, docusphere_test4
- Always use `PARALLEL_TEST_PROCESSORS=4` to ensure stable parallel execution

### Running Bundle Commands
```bash
docker-compose run --rm web bundle install
docker-compose run --rm web bundle update
```

### Running Rails Commands
```bash
docker-compose run --rm web rails db:migrate
docker-compose run --rm web rails db:seed
docker-compose run --rm web rails console
```

### Running Rake Tasks
```bash
docker-compose run --rm web rake db:setup
```

## Project-Specific Notes

- PostgreSQL reserved word: GROUP is a reserved keyword, use UserGroup model instead
- Test setup requires `require 'pundit/rspec'` in rails_helper.rb
- ViewComponent tests need `helpers.policy` instead of direct `policy` calls
- Test environment needs `config.hosts.clear` to avoid host blocking issues

## Rails Engine Routing

The ImmoPromo engine is mounted at `/immo/promo` and uses the `Immo::Promo` namespace for models and controllers.

### Route Helpers in Engine

When using route helpers within the engine's views and controllers, use the `immo_promo_engine` prefix:

```ruby
# In views and controllers within the engine:
immo_promo_engine.projects_path
immo_promo_engine.project_path(@project)
immo_promo_engine.edit_project_path(@project)
immo_promo_engine.project_phases_path(@project)
immo_promo_engine.project_phase_task_path(@project, @phase, @task)

# In ViewComponents, access through helpers:
helpers.immo_promo_engine.projects_path
helpers.immo_promo_engine.project_path(@project)
```

### From Main Application

When linking to engine routes from the main application:
```ruby
# Use the engine mount path directly:
link_to "Projets", "/immo/promo/projects"
```

## Database Migration Consolidation Plan

As of January 2025, the database migrations have been analyzed and can be consolidated from 44 files down to 8-10 comprehensive migration files. This consolidation is possible because there are no production constraints.

### Migration Categories for Consolidation:

#### 1. Core System Tables (001_create_core_system.rb)
Combines:
- Organizations
- Users (with Devise)
- Notifications
- Audited installation

#### 2. Document Management System (002_create_document_system.rb)
Combines:
- Spaces
- Folders (with parent_id, slug, treeable)
- Documents (with parent_id, all fields)
- Document versions
- Document shares
- Document tags
- Tags
- Active Storage tables

#### 3. User Groups and Authorization (003_create_authorization_system.rb)
Combines:
- User groups
- User group memberships
- Authorizations (with polymorphic associations)
- User roles and permissions
- Shares (generic sharing)

#### 4. Metadata System (004_create_metadata_system.rb)
Combines:
- Metadata templates
- Metadata fields
- Document metadata
- Metadata (polymorphic)
- Metadatum
- Search queries

#### 5. Workflow System (005_create_workflow_system.rb)
Combines:
- Workflows
- Workflow steps
- Workflow submissions
- Project workflow steps
- Project workflow transitions

#### 6. Validation System (006_create_validation_system.rb)
Combines:
- Validation requests
- Document validations
- Validation templates

#### 7. Auxiliary Features (007_create_auxiliary_features.rb)
Combines:
- Baskets
- Basket items
- Links
- User features (if any)

#### 8. Immo Promo Module (008_create_immo_promo_module.rb)
All Immo::Promo tables remain as one comprehensive migration

### Migration Consolidation Benefits:
- Reduces migration count from 44 to 8
- Eliminates incremental changes and fixes
- Creates logical groupings of related functionality
- Simplifies schema understanding
- Faster database setup

### How to Apply Consolidation:

1. **Drop existing database**:
   ```bash
   docker-compose down
   docker-compose run --rm web rails db:drop
   ```

2. **Remove old migrations**:
   ```bash
   rm -rf db/migrate/*
   ```

3. **Create new consolidated migrations**:
   Create the 8 migration files as outlined above, ensuring all fields, indexes, and constraints from the original migrations are included.

4. **Setup new database**:
   ```bash
   docker-compose run --rm web rails db:create
   docker-compose run --rm web rails db:migrate
   docker-compose run --rm web rails db:seed
   ```

### Important Considerations:
- Ensure all foreign key constraints are added in the correct order
- Maintain all unique indexes and compound indexes
- Keep all default values and null constraints
- Preserve all check constraints (e.g., authorization user/group constraint)
- Include all polymorphic association indexes