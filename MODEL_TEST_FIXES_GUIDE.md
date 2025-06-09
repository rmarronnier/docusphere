# Model Test Failures - Comprehensive Fix Guide

## Overview
Based on running the model tests, I've identified several patterns of failures across the codebase. The main issues are:

1. **Missing factories or incorrect factory associations**
2. **Tables referenced that don't exist (e.g., 'projects' table)**
3. **Concerns being tested with wrong test classes**
4. **Missing or incorrect model associations**
5. **Incorrect attribute names or missing columns**
6. **Workflow inconsistencies**

## Key Findings

### Database Tables That Exist
```
active_storage_attachments, active_storage_blobs, active_storage_variant_records,
audits, authorizations, basket_items, baskets, document_metadata, document_shares,
document_tags, document_validations, document_versions, documents, folders,
immo_promo_* (all engine tables), links, metadata, metadata_fields, metadata_templates,
metadatum, notifications, organizations, project_workflow_steps, project_workflow_transitions,
spaces, tags, user_features, user_group_memberships, user_groups, users,
validation_requests, validation_templates, versions, workflow_steps, workflow_submissions, workflows
```

### Document Model Columns
```
id, title, description, folder_id, space_id, parent_id, uploaded_by_id, document_type,
status, metadata, file_size, content_type, file_name, archived_at, is_template,
external_id, expires_at, is_public, download_count, view_count, processing_status,
virus_scan_status, content, ai_processed_at, ai_category, created_at, updated_at,
processing_started_at, processing_completed_at, processing_error, processing_metadata,
extracted_content, locked_by_id, locked_at, unlock_scheduled_at, lock_reason,
documentable_type, documentable_id, document_category, ai_confidence, ai_entities, storage_path
```

## Specific Test Failures and Fixes

### 1. Addressable Concern Test (spec/models/concerns/addressable_spec.rb)
**Error**: `PG::UndefinedTable: ERROR: relation "projects" does not exist`

**Fix**: The test is using 'projects' table which doesn't exist. Change to use an existing table with address fields:
```ruby
let(:test_class) do
  Class.new(ActiveRecord::Base) do
    self.table_name = 'immo_promo_projects' # Use the actual projects table from Immo::Promo
    include Addressable
    
    def self.name
      'TestAddressable'
    end
  end
end
```

### 2. Authorizable Concern Tests
**Multiple Failures**: Missing proper setup and associations

**Fix**: Ensure the test instance is properly saved and has required attributes:
```ruby
let(:document) { create(:document) }
let(:authorizable_instance) { document }

# Remove the generic test_class approach and use actual models
```

### 3. WorkflowManageable Concern
**Error**: Workflow model doesn't include WorkflowManageable

**Fix**: The Workflow model needs to include the concern:
```ruby
# app/models/workflow.rb
class Workflow < ApplicationRecord
  include AASM
  include WorkflowManageable # Add this line
  
  # ... rest of the model
end
```

### 4. Immo::Promo Model Tests
**Common Issues**:
- Missing factories for engine models
- Incorrect associations
- Missing enum validations

**Example Fixes**:

#### For Immo::Promo::Certification
```ruby
# Fix the factory - spec/factories/immo/promo/certifications.rb
FactoryBot.define do
  factory :immo_promo_certification, class: 'Immo::Promo::Certification' do
    association :stakeholder, factory: :immo_promo_stakeholder
    name { "ISO 9001" }
    issuing_body { "ISO Organization" }
    certification_type { "quality" }
    is_valid { true }
    issue_date { 1.year.ago }
    expiry_date { 1.year.from_now }
  end
end
```

#### For Immo::Promo::Lot
```ruby
# Fix missing associations and validations
class Immo::Promo::Lot < ApplicationRecord
  has_many :lot_specifications, class_name: 'Immo::Promo::LotSpecification', dependent: :destroy
  
  validates :lot_type, presence: true
  validates :price_cents, numericality: { greater_than: 0 }
  
  scope :available, -> { where(status: 'available') }
  
  def is_available?
    status == 'available'
  end
end
```

### 5. Factory Fixes Pattern
Most failures are due to missing or incorrect factories. Here's the pattern to fix them:

```ruby
# Bad - using wrong class name
factory :budget_line, class: 'Immo::Promo::BudgetLine' do

# Good - using consistent naming
factory :immo_promo_budget_line, class: 'Immo::Promo::BudgetLine' do
  association :budget, factory: :immo_promo_budget
  category { "construction_work" }
  planned_amount_cents { 100000 }
  # ... other attributes
end
```

### 6. Validation Fixes
Many enum validations are failing. Ensure enums are properly defined:

```ruby
# In the model
enum category: {
  land_acquisition: 'land_acquisition',
  studies: 'studies',
  construction_work: 'construction_work',
  equipment: 'equipment',
  marketing: 'marketing',
  legal: 'legal',
  administrative: 'administrative',
  contingency: 'contingency'
}

validates :category, inclusion: { in: categories.keys }
```

### 7. Association Fixes
Many associations are missing or incorrectly defined:

```ruby
# Example fix for PhaseDependency
class Immo::Promo::PhaseDependency < ApplicationRecord
  belongs_to :predecessor_phase, class_name: 'Immo::Promo::Phase'
  belongs_to :successor_phase, class_name: 'Immo::Promo::Phase'
  
  validates :dependency_type, presence: true
  validate :phases_must_be_different
  
  enum dependency_type: {
    finish_to_start: 'finish_to_start',
    start_to_start: 'start_to_start',
    finish_to_finish: 'finish_to_finish',
    start_to_finish: 'start_to_finish'
  }
  
  private
  
  def phases_must_be_different
    if predecessor_phase_id == successor_phase_id
      errors.add(:successor_phase_id, "must be different from predecessor phase")
    end
  end
end
```

## General Patterns to Fix

1. **Factory Naming Convention**: Use `immo_promo_` prefix for all Immo::Promo factories
2. **Association Factories**: Always use the full factory name in associations
3. **Enum Definitions**: Define enums with string values, not symbols
4. **Validation Inclusion**: Use `inclusion: { in: enum_name.keys }` for enum validations
5. **Concern Testing**: Use actual model instances instead of generic test classes
6. **Scope Testing**: Ensure scopes return ActiveRecord::Relation objects
7. **Money Fields**: Ensure Money gem is properly configured for monetized attributes

## Quick Fix Commands

Run these to identify specific failures:

```bash
# Run specific concern tests
docker-compose run --rm web bundle exec rspec spec/models/concerns/addressable_spec.rb

# Run Immo::Promo model tests
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/models/

# Run with specific line number for debugging
docker-compose run --rm web bundle exec rspec spec/models/concerns/addressable_spec.rb:70

# Check factory validity
docker-compose run --rm web rails runner "FactoryBot.lint"
```

## Priority Fixes

1. **Fix Workflow model** - Add WorkflowManageable concern
2. **Fix Addressable spec** - Use correct table name
3. **Create missing factories** - Especially for Immo::Promo models
4. **Fix enum validations** - Ensure all enums are properly defined
5. **Fix associations** - Add missing belongs_to and has_many declarations

## Testing Strategy

After making fixes:
1. Run individual spec files first
2. Use `--fail-fast` to catch first failure
3. Fix factories before running full suite
4. Ensure database is properly seeded for tests

This guide should help systematically fix all model test failures. Focus on one pattern at a time across all affected files for consistency.