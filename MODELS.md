# MODELS.md - Comprehensive Model Analysis

## ⚠️ IMPORTANT: Lire WORKFLOW.md avant toute modification

Ce document doit être maintenu à jour après chaque modification de modèle ou concern.

## Overview

This document provides a comprehensive analysis of all models in the Docusphere application, their business purposes, implementation details, traps, and evolution suggestions.

## 🔥 Refactoring Prioritaire (Suite à l'analyse du 09/06/2025)

### 1. **Problèmes Critiques à Corriger**

#### Duplication de Code
- **Gestion des statuts** : WorkflowManageable vs AASM - standardiser sur une approche
- **Calcul de progression** : 4 implémentations différentes - créer concern `ProgressCalculable`
- **Méthodes de permissions** : Doublons dans Authorizable (`readable_by?`/`can_read?`)

#### Incohérences
- **Validatable concern** : Contient du code spécifique à Document - à refactorer
- **owned_by?** : Vérifie différents attributs selon le modèle - à standardiser
- **WorkflowManageable** : Incompatible avec ProjectWorkflowTransition actuel

#### Code Mort
- **Concerns non utilisés** : Uploadable, Storable - à supprimer ou implémenter
- **document_version.rb** : Fichier obsolète (utilise PaperTrail) - à supprimer

### 2. **Plan de Refactoring Recommandé**

#### Phase 1 - Nettoyage (Priorité HAUTE)
1. Supprimer les concerns non utilisés (Uploadable, Storable)
2. Supprimer les méthodes dupliquées dans Authorizable
3. Refactorer Validatable pour retirer le code spécifique à Document
4. Standardiser `owned_by?` avec une approche configurable

#### Phase 2 - Standardisation (Priorité MOYENNE)
1. Choisir entre AASM et WorkflowManageable pour tous les modèles
2. Créer concern `ProgressCalculable` pour unifier le calcul de progression
3. Extraire la complexité de Document en plusieurs concerns
4. Ajouter les index manquants pour les requêtes d'autorisation

#### Phase 3 - Optimisation (Priorité BASSE)
1. Ajouter cache pour les vérifications de permissions
2. Implémenter les concerns manquants si nécessaire
3. Créer des enums partagés pour les statuts communs
4. Documenter les patterns de conception utilisés

## Core Models

### User
**Business Purpose**: Central user authentication and authorization model using Devise. Manages user profiles, roles, permissions, and relationships with organizations. Users can belong to groups, upload documents, create baskets, and participate in validation workflows. Supports multi-level roles (user, manager, admin, super_admin) with a flexible permission system.

**Key Features & Traps**:
- Uses both role-based (enum) and permission-based (JSON column) authorization
- `uploaded_by_id` foreign key links to documents (not standard `user_id`)
- Permissions can be stored as Array or Hash in JSON column - code handles both formats
- Has specific ImmoPromo module integration methods (`accessible_projects`, `can_manage_project?`)
- `has_permission?` checks both direct permissions and group permissions

**Questions/Evolution**:
- Why mix role-based and permission-based auth? Consider unified approach
- Permission storage format inconsistency (Array vs Hash) should be normalized
- Consider extracting ImmoPromo-specific methods to a concern
- Add caching for permission checks to improve performance

**Useful Patterns**:
- `add_permission!` and `remove_permission` methods for permission management
- Flexible permission checking through groups and direct assignment
- `display_name` fallback pattern (full_name || email)

### Organization
**Business Purpose**: Multi-tenant root entity that owns spaces, users, user groups, and metadata templates. Organizations provide data isolation and serve as the top-level container for all resources. Each organization has a unique slug for URL-friendly identification.

**Key Features & Traps**:
- Auto-generates slug from name if not provided
- Has direct association with `immo_promo_projects` (engine-specific)
- All dependent resources cascade delete
- No validation on settings or other business rules

**Questions/Evolution**:
- Add organization-level settings (storage quotas, feature flags)
- Consider soft-delete instead of cascade delete
- Add billing/subscription management
- Implement organization-level audit trail

**Useful Patterns**:
- Slug generation pattern for URL-friendly identifiers
- Clean cascade deletion setup

### Document ⚠️ MODÈLE CRITIQUE - 580+ lignes
**Business Purpose**: Core document management model with versioning, processing pipeline, validation workflow, and AI capabilities. Supports file uploads, metadata, tagging, sharing, locking, and state management through AASM. Documents can be organized in spaces/folders and linked to other entities via polymorphic associations.

**Key Features & Traps**:
- Uses PaperTrail for versioning with custom DocumentVersion class (inherits from PaperTrail::Version)
- Complex state machine with 6 states (draft, published, locked, archived, marked_for_deletion, deleted)
- Two separate enum systems: `processing_status` and `virus_scan_status`
- Polymorphic `documentable` association for linking to any model
- AI processing happens asynchronously after base processing completes
- Supports both direct authorization and space-level permissions
- Version tracking includes file metadata, comments, and creator information
- ⚠️ **ATTENTION**: `lock!` method override PaperTrail - voir warning au démarrage
- ⚠️ **PIÈGE**: `editable_by?` dépend de `locked_by_user?` ET `writable_by?`

**Questions/Evolution**:
- ❗ URGENT: Décomposer en concerns (Document::Lockable, Document::AIProcessable, etc.)
- State machine has many states - could be simplified
- Processing pipeline could use ActiveJob workflows
- Large model (580+ lines) - needs decomposition
- Add file blob storage strategy for version history

**Useful Patterns**:
- Comprehensive processing status tracking
- Flexible metadata system (both structured and unstructured)
- Good separation of sync/async processing
- Well-designed permission checking with multiple levels

### Space
**Business Purpose**: Container for documents and folders within an organization. Provides a way to organize content and manage permissions at a group level. Each space has unique name and slug within its organization.

**Key Features & Traps**:
- Includes Authorizable concern for permission management
- Very simple model - might be too simple for future needs
- No settings or configuration options
- Direct cascade deletion of documents and folders

**Questions/Evolution**:
- Add space-level settings (quotas, retention policies)
- Consider space templates for standard structures
- Add space-level metadata capabilities
- Implement archival instead of deletion

**Useful Patterns**:
- Clean use of Authorizable concern
- Scoped uniqueness validation pattern

### Folder
**Business Purpose**: Hierarchical organization structure within spaces using the Treeable concern. Folders can contain documents and have their own metadata. Supports nested folder structures with path tracking.

**Key Features & Traps**:
- Uses Treeable concern for hierarchy management
- Validates unique names within same parent and space
- Auto-generates slugs
- Has its own metadata system
- `full_path` method builds path from ancestors

**Questions/Evolution**:
- Consider caching the full path for performance
- Add folder templates
- Implement folder-level permissions (currently inherits from space)
- Add bulk operations support

**Useful Patterns**:
- Good use of Treeable concern
- Path building through ancestors
- Scoped uniqueness validations

## Authorization & Groups

### Authorization
**Business Purpose**: Flexible permission system supporting both user and group-based access control. Authorizations can be time-limited, revoked, and include audit trail. Supports four permission levels: read, write, admin, validate.

**Key Features & Traps**:
- Polymorphic `authorizable` - can be attached to any model
- Must have either user OR user_group (validated)
- Supports expiration dates and revocation
- Complex uniqueness validation scoped by user/group and authorizable
- Good audit trail with granted_by/revoked_by

**Questions/Evolution**:
- Consider adding custom permission types beyond the four levels
- Add permission inheritance/cascading rules
- Implement permission templates
- Add bulk permission management

**Useful Patterns**:
- Time-based permissions with expiration
- Comprehensive audit trail
- Clean scope definitions for queries
- Status helpers (active?, expired?, revoked?)

### UserGroup
**Business Purpose**: Groups users together for collective permission management. Groups belong to organizations and can have different types and active states. Members can have roles within groups (member/admin).

**Key Features & Traps**:
- Has both `is_active` flag and scope
- Group members have roles through join table
- Auto-generates slug from name
- No group hierarchy/nesting support

**Questions/Evolution**:
- Add group hierarchy for nested permissions
- Implement group templates
- Add group-level settings/preferences
- Consider LDAP/AD integration

**Useful Patterns**:
- Clean member management methods
- Role-based membership through join table
- Active/inactive state management

### UserGroupMembership
**Business Purpose**: Join table between users and groups with additional role information. Allows users to be admins or members of groups with different permission implications.

**Key Features & Traps**:
- Simple join table with role field
- Only two roles: member/admin
- Inherits permissions from group
- No additional metadata

**Questions/Evolution**:
- Add more granular roles
- Add membership expiration
- Track membership history
- Add invitation workflow

## Validation System

### ValidationRequest
**Business Purpose**: Orchestrates document validation workflows by tracking validation requests, required validators, and approval status. Supports minimum validation thresholds and rejection workflows.

**Key Features & Traps**:
- Uses string-based enum (not integer) with explicit attribute declaration
- Complex state management with status tracking
- Auto-updates status based on validation responses
- One rejection = entire request rejected
- Good logging for debugging state changes

**Questions/Evolution**:
- Add weighted validations (some validators more important)
- Implement validation deadlines with reminders
- Add validation templates for common scenarios
- Consider async status updates for performance

**Useful Patterns**:
- Automatic completion checking after each validation
- Progress tracking with percentages
- Comprehensive notification triggers
- Good separation of concerns with NotificationService

### DocumentValidation
**Business Purpose**: Individual validation response from a validator for a document. Tracks approval/rejection with comments and timestamps.

**Key Features & Traps**:
- Links to both Document and ValidationRequest
- Simple status tracking (pending/approved/rejected)
- Triggers parent request completion check on update

**Questions/Evolution**:
- Add validation criteria/checklist
- Implement conditional validations
- Add file attachments to validations
- Track time spent on validation

## Workflow System

### Workflow
**Business Purpose**: Defines reusable multi-step processes with state management. Workflows contain ordered steps and track submissions. Uses AASM for state machine.

**Key Features & Traps**:
- Five states: draft, active, paused, completed, cancelled
- Only active workflows can receive submissions
- No step dependencies or branching logic
- Progress calculated from step completion

**Questions/Evolution**:
- Add conditional branching between steps
- Implement parallel step execution
- Add workflow templates marketplace
- Add SLA/deadline tracking

**Useful Patterns**:
- Clean state machine implementation
- Progress percentage calculation
- Activation requirements checking

### WorkflowStep
**Business Purpose**: Individual step within a workflow that can be assigned to users or groups. Tracks completion status and who completed it.

**Key Features & Traps**:
- Can be assigned to user OR group (not both)
- Five states: pending, in_progress, completed, rejected, skipped
- Position field for ordering
- No deadline or duration tracking

**Questions/Evolution**:
- Add step dependencies and conditions
- Implement step templates
- Add time tracking and deadlines
- Support multiple assignees

### WorkflowSubmission
**Business Purpose**: Instance of a workflow execution for a specific item (document, project, etc). Links workflows to actual work items.

**Key Features & Traps**:
- Polymorphic `submittable` association
- Tracks submission and completion
- Links to user who submitted
- No progress tracking at submission level

**Questions/Evolution**:
- Add submission-level progress tracking
- Implement submission templates
- Add bulk submission support
- Track submission history/attempts

## Metadata System

### MetadataTemplate
**Business Purpose**: Defines structured metadata schemas for organizations. Templates contain fields that enforce data types and validation rules.

**Key Features & Traps**:
- Organization-scoped templates
- Has many metadata fields
- No versioning of templates
- No template inheritance

**Questions/Evolution**:
- Add template versioning
- Implement template inheritance
- Add conditional fields
- Support computed fields

### MetadataField
**Business Purpose**: Defines individual fields within metadata templates including type, validation rules, and options for select fields.

**Key Features & Traps**:
- Supports multiple field types (text, integer, date, select, etc.)
- JSON column for select options
- No field dependencies
- No custom validation rules

**Questions/Evolution**:
- Add field dependencies and conditional logic
- Support custom validation rules
- Add field templates
- Implement calculated fields

### Metadatum
**Business Purpose**: Actual metadata values attached to any model via polymorphic association. Can be structured (via template) or flexible (key-value).

**Key Features & Traps**:
- Polymorphic association to any model
- Validates value based on field type if structured
- Flexible key-value storage if no template
- Complex uniqueness validation logic

**Questions/Evolution**:
- Add metadata versioning
- Implement bulk metadata operations
- Add metadata inheritance from parent objects
- Support metadata transformations

**Useful Patterns**:
- Flexible structured vs unstructured approach
- Type validation based on field definition
- Display value formatting

## Supporting Models

### DocumentVersion
**Business Purpose**: Custom PaperTrail::Version subclass for tracking document version history with file metadata, comments, and creator information. Provides document-specific versioning features like file size tracking, restoration capabilities, and version comparison.

**Key Features & Traps**:
- Inherits from PaperTrail::Version but adds document-specific functionality
- Stores file metadata in JSON column (filename, size, content type, checksum)
- Tracks who created each version via created_by association
- Supports version restoration with audit trail
- Auto-generates version numbers sequentially per document
- Provides human-readable file sizes and event descriptions

**Questions/Evolution**:
- Consider storing actual file blobs for true version history
- Add diff visualization between versions
- Implement version compression/archival for old versions
- Add version tagging/labeling capabilities

**Useful Patterns**:
- Clean separation of concerns with PaperTrail
- Metadata storage pattern for file information
- Version restoration with new audit entry
- Scope-based filtering for document versions only

### Tag
**Business Purpose**: Simple tagging system for documents. Tags are organization-scoped and normalized to lowercase.

**Key Features & Traps**:
- Auto-normalizes name to lowercase
- Organization-scoped uniqueness
- Many-to-many with documents via join table
- No tag hierarchy or categories

**Questions/Evolution**:
- Add tag categories/groups
- Implement tag synonyms
- Add tag usage analytics
- Support tag policies/restrictions

### Notification
**Business Purpose**: Comprehensive notification system supporting multiple types of events across the application. Tracks read status and supports polymorphic associations to any notifiable object.

**Key Features & Traps**:
- Extensive enum with 30+ notification types
- Polymorphic `notifiable` association
- Good helper methods for icons and colors
- Time-based scopes for filtering
- Supports structured data in JSON column

**Questions/Evolution**:
- Consider extracting notification types to configuration
- Add notification preferences per type
- Implement notification batching/digests
- Add real-time delivery via ActionCable

**Useful Patterns**:
- Category-based organization of types
- Urgency classification system
- Rich UI helpers (icons, colors)
- Flexible data storage for context

### Basket
**Business Purpose**: Personal or shared collections of documents. Similar to shopping cart concept for batch operations.

**Key Features & Traps**:
- Polymorphic items (not just documents)
- Sharing capability with expiration
- Position tracking for ordering
- No versioning of basket contents

**Questions/Evolution**:
- Add basket templates
- Implement collaborative baskets
- Add basket operations (export, process)
- Track basket history

### Link
**Business Purpose**: Creates relationships between any two objects in the system via polymorphic associations.

**Key Features & Traps**:
- Double polymorphic (source and target)
- No link types or categories
- No bidirectional link handling
- Simple model, maybe too simple

**Questions/Evolution**:
- Add link types/categories
- Implement bidirectional links
- Add link metadata
- Support link validation rules

## Concerns

### Authorizable ⚠️ CONCERN CRITIQUE
**Business Purpose**: Adds authorization capabilities to any model. Provides methods for granting, revoking, and checking permissions at multiple levels.

**Key Features & Traps**:
- Complex SQL queries for permission checking
- Handles both user and group permissions
- ❗ **DUPLICATION**: Multiple helper methods with similar names (can_read?, readable_by?)
- Owner bypass logic for permissions
- ⚠️ **PIÈGE**: `owned_by?` vérifie différents attributs:
  - `user` (cas général)
  - `uploaded_by` (Document)
  - `project_manager` (ImmoPromo::Project)

**Questions/Evolution**:
- ❗ URGENT: Supprimer les méthodes dupliquées
- Add caching layer for permission checks
- Simplify method naming conventions
- Add bulk permission operations
- Implement permission inheritance rules

**Useful Patterns**:
- Unified interface for permissions
- Owner bypass pattern
- Scope-based permission queries

### Treeable
**Business Purpose**: Adds hierarchical tree structure capabilities to models with parent-child relationships, path tracking, and circular reference prevention.

**Key Features & Traps**:
- Prevents circular references
- Builds ancestor/descendant chains recursively (performance concern)
- No depth limits
- No caching of paths

**Questions/Evolution**:
- Add path caching for performance
- Implement depth limits
- Add tree operations (move subtree, copy)
- Use materialized path or nested set pattern

**Useful Patterns**:
- Circular reference prevention
- Path building helpers
- Depth calculation

### Validatable
**Business Purpose**: Adds validation workflow capabilities to any model. Handles validation requests, tracks validators, and manages approval flows.

**Key Features & Traps**:
- Duplicates some Document validation logic
- Complex relationship setup
- No validation templates
- Status tracking could conflict with model's own status

**Questions/Evolution**:
- Consolidate with Document validation logic
- Add validation criteria system
- Implement validation workflows
- Add delegation support

### Uploadable
**Business Purpose**: Adds file upload and processing capabilities to models including virus scanning, content extraction, and preview generation.

**Key Features & Traps**:
- Assumes ActiveStorage setup
- Hard-coded job names
- No upload progress tracking
- Virus scan integration needs external service

**Questions/Evolution**:
- Add upload progress tracking
- Make job names configurable
- Add chunked upload support
- Implement upload policies

**Useful Patterns**:
- Comprehensive file metadata
- Automatic preview/thumbnail generation
- File type validation system

### Storable
**Business Purpose**: Manages storage location and organization for models (not found in codebase but referenced).

**Questions/Evolution**:
- Implement if needed for storage abstraction
- Consider cloud storage integration
- Add storage policies and quotas

### Linkable  
**Business Purpose**: Adds linking capabilities between models (not found in codebase but referenced).

**Questions/Evolution**:
- Implement to standardize linking
- Consider graph database for complex relationships
- Add link types and validation

## Key Observations

### Overall Architecture Patterns
1. **Heavy use of concerns** for shared behavior
2. **Polymorphic associations** used extensively for flexibility
3. **State machines** (AASM) for complex workflows
4. **JSON columns** for flexible data storage
5. **Comprehensive authorization** system with multiple levels

### Common Traps
1. **Permission checking performance** - lots of complex SQL queries without caching
2. **Large models** - Document model has 580+ lines
3. **Duplicate patterns** - validation logic exists in multiple places
4. **Inconsistent data formats** - permissions stored as Array or Hash
5. **Missing indexes** - some polymorphic associations might need composite indexes

### Suggested Improvements
1. **Extract large models** into smaller concerns/services
2. **Add caching layer** for permissions and paths
3. **Standardize JSON column formats**
4. **Create model documentation** for complex relationships
5. **Add performance monitoring** for recursive operations
6. **Implement soft deletes** instead of hard deletes
7. **Add model-level event system** for better decoupling

### Useful Patterns to Reuse
1. **Slug generation** - consistent pattern across models
2. **Status tracking** with state machines
3. **Polymorphic associations** for flexibility
4. **Scope definitions** for common queries
5. **Audit trail** with granted_by/revoked_by pattern
6. **Progress calculation** helpers
7. **Human-readable formatting** methods