# Test Failure Analysis - Prioritized Fixes

## Critical Issues (Fix First)

### 1. Document Model - PaperTrail Configuration Error
**Error**: `ArgumentError: wrong number of arguments (given 1, expected 0)`
**Location**: `app/models/document.rb:69`
**Issue**: The lambda for `created_by_id` in PaperTrail meta configuration is incorrect
```ruby
# Current (incorrect):
created_by_id: -> { Current.user&.id }

# Should be:
created_by_id: proc { Current.user&.id }
```
**Impact**: This affects ALL tests that create documents (many tests fail due to this)

### 2. Document Version Model Deletion Conflict
**Issue**: The `document_version.rb` model was deleted but the table still exists in schema
**Fix Options**:
- Create a migration to drop the `document_versions` table
- OR restore the model if it's actually needed
**Note**: Per CLAUDE.md, documents use PaperTrail for versioning, so this table is redundant

## Model/Factory Issues

### 3. Immo::Promo::BudgetLine Model
**Error**: `'invalid_category' is not a valid category`
**Issue**: The model uses enum with string values, test is passing invalid category
**Fix**: Update test to use valid categories from the enum

### 4. Immo::Promo::BudgetLine#is_over_budget? Method
**Error**: Method returns `nil` instead of `false` when actual_amount is nil
**Fix**: Update method to explicitly return false:
```ruby
def is_over_budget?
  return false unless actual_amount
  actual_amount > planned_amount
end
```

## Routing/Path Helper Issues

### 5. Timeline Component - Missing Route Helper
**Error**: `undefined method 'immo_promo_project_immo_promo_phase_path'`
**Issue**: Route helper is incorrect, should use engine prefix
**Fix**: Update component to use correct helper:
```ruby
# Should be:
helpers.immo_promo_engine.project_phase_path(@project, phase)
```

## Test-Specific Issues

### 6. Addressable Concern Test
**Error**: `PG::UndefinedTable: ERROR: relation "projects" does not exist`
**Issue**: Test is trying to create a table that doesn't exist
**Fix**: Update test to use an existing model or create a test-specific model

## Factory Definition Issues

### 7. Missing or Incorrect Factory Attributes
Based on schema analysis, these factories may need updates:
- **workflow_submissions**: Ensure all required attributes are set
- **document_shares**: Check email/shared_with_id logic
- **basket_items**: Verify polymorphic association setup

## Enum Declaration Issues

### 8. Check Enum Declarations
Models using enums that may need verification:
- Immo::Promo::BudgetLine (category)
- Document (status, processing_status, virus_scan_status)
- Workflow (status)
- WorkflowSubmission (status, priority)

## Recommended Fix Order

1. **Fix Document PaperTrail configuration** (impacts many tests)
2. **Handle document_versions table removal**
3. **Fix BudgetLine#is_over_budget? method**
4. **Update Timeline Component route helpers**
5. **Fix enum-related test failures**
6. **Update factory definitions as needed**
7. **Fix remaining routing/path issues**

## Quick Fixes Script

```bash
# Run specific failing tests after fixes to verify:
docker-compose run --rm web bundle exec rspec spec/models/document_spec.rb --fail-fast
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/models/immo/promo/budget_line_spec.rb --fail-fast
docker-compose run --rm web bundle exec rspec engines/immo_promo/spec/components/immo/promo/timeline_component_spec.rb --fail-fast
```