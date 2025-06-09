# CLAUDE.md - AI Assistant Instructions

## 🚨 OBLIGATOIRE : Lire WORKFLOW.md avant TOUTE session

Ce fichier contient les procédures obligatoires pour éviter les régressions. **NE PAS** commencer une session sans avoir lu et compris WORKFLOW.md.

## Important Rules

**NEVER run git commands directly**. Always let the user handle git operations.

**⚠️ DOCUMENT VERSIONING**: Document model uses PaperTrail for versioning with a custom DocumentVersion class that inherits from PaperTrail::Version. This provides document-specific versioning features while leveraging PaperTrail's robust infrastructure. Access versions through `document.versions` which returns DocumentVersion instances.

## ⚠️ Pièges Connus (Mis à jour 09/06/2025)

1. **Document#lock!** : Override la méthode PaperTrail - cause un warning au démarrage
2. **Authorizable#owned_by?** : Vérifie différents attributs selon le modèle (user, uploaded_by, project_manager)
3. **WorkflowManageable** : Incompatible avec Workflow model (utilise des statuts différents)
4. **Tests parallèles** : Utiliser SEULEMENT en local, jamais sur GitHub Actions
5. **Factories avec associations** : Toujours vérifier le schema.rb pour les colonnes réelles

## GitHub Actions Compatibility

When running on GitHub Actions (x86_64-linux), you may need to add the platform to Gemfile.lock:
```bash
docker-compose run --rm web bundle lock --add-platform x86_64-linux
```

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

System tests use Chromium with Selenium WebDriver in headless mode. The configuration is set up in `spec/support/capybara.rb`:

- **Driver**: Chromium in headless mode (`:chrome_headless`)
- **Browser options**: Configured for Docker environment with `--no-sandbox`, `--disable-dev-shm-usage`
- **Screenshots**: Automatically saved to `tmp/screenshots/` when tests fail
- **Engine support**: Both main app and engine system tests are configured

**Running System Tests**:
```bash
# Run all system tests
docker-compose run --rm web bundle exec rspec spec/system/

# Run specific system test
docker-compose run --rm web bundle exec rspec spec/system/document_upload_workflow_spec.rb

# Run engine system tests
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/system/
```

**Note**: The Dockerfile.dev includes Chromium and chromium-driver for system test support.

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