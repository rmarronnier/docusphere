# Missing Test Files Report

Generated on: 11/06/2025

## Summary

This report identifies all Ruby classes and modules that are missing their corresponding test files.

## Main Application

### Models Missing Tests (9 files)
- `app/models/application_record.rb` → Missing `spec/models/application_record_spec.rb`
- `app/models/current.rb` → Missing `spec/models/current_spec.rb`
- `app/models/document_metadata.rb` → Missing `spec/models/document_metadata_spec.rb`
- `app/models/document_version.rb` → Missing `spec/models/document_version_spec.rb`

### Model Concerns Missing Tests (5 files)
- `app/models/concerns/documents/ai_processable.rb` → Missing `spec/models/concerns/documents/ai_processable_spec.rb`
- `app/models/concerns/documents/lockable.rb` → Missing `spec/models/concerns/documents/lockable_spec.rb`
- `app/models/concerns/documents/processable.rb` → Missing `spec/models/concerns/documents/processable_spec.rb`
- `app/models/concerns/documents/versionable.rb` → Missing `spec/models/concerns/documents/versionable_spec.rb`
- `app/models/concerns/documents/virus_scannable.rb` → Missing `spec/models/concerns/documents/virus_scannable_spec.rb`

### Controllers Missing Tests (3 files)
- `app/controllers/concerns/ged/bulk_operations.rb`
- `app/controllers/concerns/ged/document_versioning.rb`
- `app/controllers/ged_controller_old.rb`

### Services Missing Tests (14 files)
#### NotificationService modules (5 files)
- `app/services/notification_service/budget_notifications.rb`
- `app/services/notification_service/permit_notifications.rb`
- `app/services/notification_service/project_notifications.rb`
- `app/services/notification_service/risk_notifications.rb`
- `app/services/notification_service/stakeholder_notifications.rb`
- `app/services/notification_service/user_utilities.rb`
- ✅ `app/services/notification_service/document_notifications.rb` has test
- ✅ `app/services/notification_service/validation_notifications.rb` has test

#### RegulatoryComplianceService modules (6 files)
- `app/services/regulatory_compliance_service/gdpr_compliance.rb`
- `app/services/regulatory_compliance_service/real_estate_compliance.rb`
- `app/services/regulatory_compliance_service/contractual_compliance.rb`
- `app/services/regulatory_compliance_service/environmental_compliance.rb`
- `app/services/regulatory_compliance_service/core_operations.rb`
- `app/services/regulatory_compliance_service/financial_compliance.rb`

#### MetricsService modules (3 files)
- `app/services/metrics_service/core_calculations.rb`
- `app/services/metrics_service/business_metrics.rb`
- `app/services/metrics_service/widget_data.rb`

#### Other Services (1 file)
- `app/services/tree_path_cache_service.rb`

### Jobs Missing Tests (8 files)
- `app/jobs/application_job.rb`
- `app/jobs/auto_tagging_job.rb`
- `app/jobs/document_ai_processing_job.rb`
- `app/jobs/metadata_extraction_job.rb`
- `app/jobs/ocr_processing_job.rb`
- `app/jobs/preview_generation_job.rb`
- `app/jobs/thumbnail_generation_job.rb`
- `app/jobs/virus_scan_job.rb`

### Components Missing Tests (2 files)
- `app/components/concerns/accessible.rb`
- `app/components/ui/description_list_component.rb`

### Policies Missing Tests (1 file)
- `app/policies/application_policy.rb`

## Immo::Promo Engine

### Engine Models Missing Tests (2 files)
- `engines/immo_promo/app/models/immo_promo/application_record.rb`
- `engines/immo_promo/app/models/concerns/immo/promo/workflow_states.rb`

### Engine Controllers Missing Tests (2 files)
- `engines/immo_promo/app/controllers/immo_promo/application_controller.rb`
- `engines/immo_promo/app/controllers/immo/promo/financial_dashboard_controller_original.rb`

### Engine Services Missing Tests (0 files)
✅ All engine service concerns have tests in `engines/immo_promo/spec/services/concerns/`

### Engine Policies Missing Tests (3 files)
- `engines/immo_promo/app/policies/immo/promo/application_policy.rb`
- `engines/immo_promo/app/policies/immo/promo/budget_line_policy.rb`
- `engines/immo_promo/app/policies/immo/promo/budget_policy.rb`

## Total Missing Tests

- **Main Application**: 42 files  
- **Immo::Promo Engine**: 7 files (was 11, but 4 engine service concerns have tests)
- **Total**: 49 files

## Priority Recommendations

### High Priority (Core functionality)
1. Document-related concerns (ai_processable, lockable, processable, versionable, virus_scannable)
2. Services with modular components (NotificationService, RegulatoryComplianceService, MetricsService)
3. Background jobs (especially document processing jobs)

### Medium Priority (Supporting functionality)
1. Engine service concerns (allocation and task coordination)
2. Engine policies
3. Component concerns

### Low Priority (Base classes and deprecated)
1. ApplicationRecord classes
2. ApplicationPolicy classes
3. ged_controller_old.rb (appears to be deprecated)

## Notes

1. **Base Classes** - May not require tests:
   - `app/models/application_record.rb` - Base Rails class
   - `app/policies/application_policy.rb` - Base Pundit class
   - `app/jobs/application_job.rb` - Base Rails job class
   - `engines/immo_promo/app/models/immo_promo/application_record.rb` - Engine base class
   - `engines/immo_promo/app/controllers/immo_promo/application_controller.rb` - Engine base controller
   - `engines/immo_promo/app/policies/immo/promo/application_policy.rb` - Engine base policy

2. **Deprecated Files** - Should be removed:
   - `app/controllers/ged_controller_old.rb` - Old controller, replaced by current ged_controller.rb
   - `engines/immo_promo/app/controllers/immo/promo/financial_dashboard_controller_original.rb` - Backup file

3. **Recently Refactored**:
   - Document concerns (ai_processable, lockable, etc.) were consolidated from individual files
   - These might be tested through the Document model tests

4. **Service Modules**:
   - NotificationService modules are likely tested through integration tests
   - RegulatoryComplianceService and MetricsService modules may be tested through their parent services

5. **Special Cases**:
   - `app/models/current.rb` - ActiveSupport::CurrentAttributes for thread-local storage
   - `app/models/document_metadata.rb` - Join model between Document and MetadataTemplate
   - `app/models/document_version.rb` - PaperTrail custom version class

## Actionable Summary

### Files That NEED Tests (Priority Order)

1. **Document Concerns** (5 files) - Core functionality
   - Write tests for all document concerns in `spec/models/concerns/documents/`

2. **Active Models** (2 files)
   - `app/models/document_metadata.rb` - Has validations and associations
   - `app/models/document_version.rb` - Custom version class

3. **Background Jobs** (7 files) - Critical for document processing
   - All jobs except `application_job.rb`

4. **Service Modules** (11 files) - Business logic
   - NotificationService modules (5 files)
   - RegulatoryComplianceService modules (6 files)

5. **Components** (2 files)
   - `app/components/ui/description_list_component.rb`
   - `app/components/concerns/accessible.rb`

6. **Engine Policies** (2 files)
   - `engines/immo_promo/app/policies/immo/promo/budget_line_policy.rb`
   - `engines/immo_promo/app/policies/immo/promo/budget_policy.rb`

### Files to REMOVE (2 files)
- `app/controllers/ged_controller_old.rb`
- `engines/immo_promo/app/controllers/immo/promo/financial_dashboard_controller_original.rb`

### Files that DON'T NEED Tests (8 files)
- All ApplicationRecord/Controller/Policy base classes
- `app/models/current.rb` (ActiveSupport::CurrentAttributes)
- Controller concerns (might be tested through controllers)

**Estimated Real Missing Tests: ~31 files** (excluding base classes and deprecated files)