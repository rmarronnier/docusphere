# ImmoPromo Models Documentation

## Overview
The ImmoPromo engine implements a comprehensive real estate project management system with 21 domain models. The models follow a hierarchical structure centered around Projects, with Phases and Tasks forming the work breakdown structure.

## Core Models

### 1. Project (`Immo::Promo::Project`)

**Business Purpose:**
The central entity representing a real estate development project. Projects can be residential, commercial, mixed-use, office, retail, or industrial. Each project has phases, tasks, lots, stakeholders, permits, budgets, contracts, and risks. Projects track overall progress, budget usage, and critical milestones. The model includes comprehensive progress calculation methods and validation workflows.

**Traps & Peculiarities:**
- Uses `total_budget_cents` as a bigint instead of integer (migration needed)
- Has multiple attached file collections (technical, administrative, financial documents)
- Aliases `end_date` to `expected_completion_date` for Schedulable concern
- WorkflowManageable is temporarily disabled with a comment about "model mismatch"
- `total_surface_area` method rescues ActiveRecord::StatementInvalid errors
- Heavy use of complex queries in stakeholder methods that could cause N+1 issues

**Questions & Suggestions:**
- Why is WorkflowManageable disabled? This seems critical for project workflows
- Consider using counter caches for phases/tasks counts to optimize progress calculations
- The phase_weight method uses hardcoded values - should these be configurable?
- Missing validations for budget fields and dates
- Consider extracting progress calculation logic into a service object

**Useful Information:**
- Implements Addressable, Schedulable, Authorizable concerns
- Has audited for tracking changes
- Monetize integration for budget fields
- Complex progress calculation methods (task-based and phase-based)
- Critical path analysis methods
- Stakeholder workload analysis

### 2. Phase (`Immo::Promo::Phase`)

**Business Purpose:**
Represents a major stage in a project lifecycle (studies, permits, construction, finishing, delivery, reception). Phases have dependencies on other phases, contain tasks and milestones, and track their own budget and progress. Each phase can be marked as critical for the project's critical path. Phases implement a position-based ordering system within projects.

**Traps & Peculiarities:**
- Has both `dependent_phases` and `prerequisite_phases` through different associations
- Position must be unique within a project scope
- Duplicated `delayed` scope definition
- Uses WorkflowManageable but doesn't seem to have workflow states defined
- No validation on budget fields being positive

**Questions & Suggestions:**
- Consider adding state machine for phase lifecycle management
- The `can_start?` method only checks prerequisites completion, not dates
- Missing validation that start_date < end_date
- Should phases inherit project's organization for authorization?
- Consider caching completion_percentage to avoid recalculation

**Useful Information:**
- Implements Schedulable and WorkflowManageable concerns
- Has phase dependencies with circular dependency detection
- Monetized budget tracking (budget vs actual_cost)
- Document types vary by phase type
- Critical path support with is_critical flag

### 3. Task (`Immo::Promo::Task`)

**Business Purpose:**
Represents individual work items within a phase. Tasks can be assigned to users or stakeholders, have dependencies on other tasks, track time logs, and manage deliverables. Tasks support various types (planning, execution, review, approval, milestone, administrative, technical) and priorities. They calculate progress based on logged hours vs estimated hours.

**Traps & Peculiarities:**
- Can be assigned to either a User OR a Stakeholder (not both)
- Uses `checklist` JSONB column to store `required_skills` via store_accessor
- Has multiple attached file collections (deliverables, references)
- Progress calculation assumes hours logged equals completion (may not be accurate)
- `actual_hours` and `total_logged_hours` methods do the same thing

**Questions & Suggestions:**
- Why separate assignment to users vs stakeholders? Consider unified assignment
- Progress should potentially consider task status, not just hours
- Missing validation for task assignment conflicts
- Consider adding actual_start_date and actual_end_date fields
- The completion_status method returns French strings - should use I18n

**Useful Information:**
- Full dependency management with circular detection
- Time tracking through TimeLog model
- Multiple file attachments support
- Implements all standard concerns (Schedulable, WorkflowManageable, Documentable)
- Rich scoping options for filtering

### 4. Budget (`Immo::Promo::Budget`)

**Business Purpose:**
Manages project financial planning with support for initial, revised, and final budgets. Each budget has multiple budget lines categorizing expenses. Tracks total amount vs spent amount to monitor budget consumption. Only one budget can be marked as current per project. Budgets are versioned to maintain history of financial planning changes.

**Traps & Peculiarities:**
- No validation ensuring only one budget is current per project
- `spending_percentage` doesn't handle nil spent_amount gracefully
- Version uniqueness is scoped to project but no auto-increment logic
- No foreign key constraint ensuring budget lines don't exceed total

**Questions & Suggestions:**
- Add callback to ensure only one current budget per project
- Add validation that spent_amount <= total_amount
- Consider adding approved_by and approval_date fields
- Missing currency handling - assumes all Money objects use same currency
- Should budget lines be validated to sum up to total_amount?

**Useful Information:**
- Monetized fields with money-rails
- Audited for change tracking
- Has dependent destroy for budget lines
- Enum for budget types
- Helper methods for variance calculation

### 5. BudgetLine (`Immo::Promo::BudgetLine`)

**Business Purpose:**
Represents individual expense categories within a budget (land acquisition, studies, construction work, equipment, marketing, legal, administrative, contingency). Tracks planned vs actual vs committed amounts. Provides spending analysis at the category level. Budget lines can be deleted only if no money has been spent or committed.

**Traps & Peculiarities:**
- Uses aliases for backward compatibility (amount_cents, spent_amount_cents)
- Hardcoded EUR currency in Money objects
- No validation that actual_amount <= planned_amount
- No validation preventing negative amounts for committed_amount

**Questions & Suggestions:**
- Consider adding a locked flag to prevent modifications after approval
- Add scope for over-budget lines
- The currency should be configurable, not hardcoded
- Missing indexes on category for filtering performance
- Add validation for the sum of committed + actual <= planned

**Useful Information:**
- Three-way tracking: planned, actual, committed amounts
- Deletion protection based on financial commits
- Category-based organization
- Monetized fields for all amounts
- Helper methods for variance analysis

### 6. Lot (`Immo::Promo::Lot`)

**Business Purpose:**
Represents individual units in a real estate project (apartments, houses, commercial units, parking spaces, storage units, offices). Each lot has specifications, can be reserved, and tracks its construction status. Lots maintain pricing information and physical characteristics like surface area, floor level, and room count. Essential for sales tracking and project completion monitoring.

**Traps & Peculiarities:**
- Floor validation allows negative values (for basements) down to -3
- Multiple price-related aliases that all point to the same field
- No validation ensuring lot surface areas sum to project total
- Status transitions aren't validated (can go from sold back to planned)

**Questions & Suggestions:**
- Consider state machine for status transitions
- Add validation that reserved lots have active reservations
- The rooms_description method uses French - needs I18n
- Missing fields for orientation, view, parking allocation
- Should track price history, not just current price

**Useful Information:**
- Rich categorization by type and status
- Supports file attachments for plans and technical sheets
- Reservation management integration
- Surface area calculations including balconies
- Status-based completion percentage

### 7. Stakeholder (`Immo::Promo::Stakeholder`)

**Business Purpose:**
Represents external parties involved in the project (architects, engineers, contractors, subcontractors, consultants, control offices, clients, investors, legal advisors). Stakeholders can be assigned tasks, have contracts, require certifications (insurance, qualifications), and receive notifications. The model tracks workload to prevent overallocation and monitors performance based on task completion.

**Traps & Peculiarities:**
- Complex aliasing system for compatibility (is_critical, notification_enabled, contact fields)
- SIRET validation is basic (only length 14) - should validate format
- Workload calculations in methods could be expensive without proper indexes
- The `full_address` method returns French text - needs I18n
- Performance rating logic embedded in model rather than service

**Questions & Suggestions:**
- Extract performance/workload calculations to a service
- Add caching for expensive calculations like engagement_score
- SIRET should have proper French business number validation
- Consider separate Contact model for multiple contacts per stakeholder
- Add support for stakeholder availability calendar

**Useful Information:**
- Includes Addressable concern for address management
- Comprehensive certification tracking
- Workload and performance analytics
- Task conflict detection
- Qualification validation for specific roles (architects need registration)

### 8. Permit (`Immo::Promo::Permit`)

**Business Purpose:**
Manages regulatory permits required for real estate projects (urban planning, construction, demolition, environmental, modification, declaration). Tracks permit lifecycle from draft through submission to approval/denial, including appeal process. Monitors expiry dates and conditions that must be fulfilled. Critical for ensuring legal compliance and preventing project delays.

**Traps & Peculiarities:**
- Multiple date field aliases causing confusion (start_date, end_date, submitted_date, expiry_date)
- Has three different attached file collections (permit_documents, response_documents, documents)
- Complex urgency calculation logic embedded in model
- Expected decision date calculation uses hardcoded day values by permit type
- No validation ensuring approved permits have an approved_by user

**Questions & Suggestions:**
- Clarify date field purposes and remove confusing aliases
- Extract urgency and deadline calculations to a service
- Add workflow states for permit lifecycle
- Consider adding renewal tracking for expired permits
- The hardcoded processing days should be configurable

**Useful Information:**
- Comprehensive status tracking through lifecycle
- Permit condition management
- Authority and submission tracking
- Urgency level calculations for prioritization
- Integration with project construction readiness

### 9. Contract (`Immo::Promo::Contract`)

**Business Purpose:**
Manages contracts with stakeholders covering various services (architecture, engineering, construction, subcontracting, consulting, insurance, legal). Tracks contract amounts, payment progress, and contract lifecycle from draft to completion. Supports contract amendments through attached documents. Essential for financial tracking and stakeholder relationship management.

**Traps & Peculiarities:**
- Uses 'reference' alias for contract_number but validates 'reference' not 'contract_number'
- No validation that paid_amount doesn't exceed amount
- No support for contract renewals or extensions
- Missing payment schedule/milestone tracking

**Questions & Suggestions:**
- Add payment schedule/milestones for better cash flow management
- Implement contract template system for standard contracts
- Add support for multi-year contracts with renewal
- Consider adding penalty/bonus tracking
- Need contract approval workflow

**Useful Information:**
- Monetized amount tracking
- Payment progress monitoring
- Amendment support through attachments
- Schedulable concern for date management
- Audited for change tracking

### 10. Risk (`Immo::Promo::Risk`)

**Business Purpose:**
Identifies and tracks project risks across multiple categories (technical, financial, legal, regulatory, environmental, timeline, quality, external). Uses probability and impact matrix to calculate risk scores and priority levels. Supports risk mitigation planning and monitoring. Critical for proactive project management and avoiding costly surprises.

**Traps & Peculiarities:**
- Has three different aliases for user association (identified_by, assigned_to, owner)
- Risk score calculation uses hardcoded score values
- No tracking of mitigation actions or their effectiveness
- Missing risk history/evolution tracking
- Category is stored but also aliased as risk_type

**Questions & Suggestions:**
- Add MitigationAction model to track response strategies
- Implement risk register with historical tracking
- Add cost impact estimation for financial risks
- Consider risk interdependency mapping
- Add risk review/reassessment scheduling

**Useful Information:**
- 5x5 probability/impact matrix
- Automatic risk scoring and level calculation
- Status workflow from identified to closed
- High priority filtering for critical risks
- Enum-based categorization

### 11. Milestone (`Immo::Promo::Milestone`)

**Business Purpose:**
Represents key project events or deliverables that mark significant progress points. Includes permit submissions/approvals, construction start/completion, delivery, and legal deadlines. Can be marked as critical for project success. Tracks target vs actual dates to monitor schedule performance. Used for high-level project reporting and stakeholder communication.

**Traps & Peculiarities:**
- No validation ensuring milestone dates align with phase dates
- Status enum includes 'delayed' but no automatic status update logic
- No dependency management between milestones
- Missing integration with project critical path

**Questions & Suggestions:**
- Add automatic status updates based on dates
- Implement milestone dependencies
- Add notification system for upcoming critical milestones
- Consider milestone templates for standard project types
- Add completion criteria/checklist

**Useful Information:**
- Links to phases rather than directly to projects
- Variance tracking for schedule performance
- Critical milestone flagging
- Audited for change tracking
- Completion date flexibility (completed_at or actual_date)

### 12. Reservation (`Immo::Promo::Reservation`)

**Business Purpose:**
Manages the sales process for lots, tracking reservations from initial interest through to confirmation or cancellation. Includes deposit management, pricing, and expiry tracking. Supports multiple reservation statuses and prevents double-booking of lots. Critical for sales pipeline management and revenue forecasting.

**Traps & Peculiarities:**
- No validation preventing multiple active reservations per lot
- No automatic status update when reservation expires
- Missing commission/agent tracking
- No support for reservation transfers between clients
- Currency handling assumes single currency

**Questions & Suggestions:**
- Add unique constraint on lot_id for active reservations
- Implement automatic expiry job/service
- Add sales agent assignment and commission tracking
- Support for reservation upgrades/downgrades
- Add document attachment support for contracts

**Useful Information:**
- Deposit amount and percentage tracking
- Expiry date monitoring
- Client information storage
- Final price negotiation support
- Status-based scoping for active reservations

### 13. LotSpecification (`Immo::Promo::LotSpecification`)

**Business Purpose:**
Details the features and requirements of individual lots including finishes, equipment, technical requirements, environmental features, and accessibility options. Distinguishes between standard and custom specifications. Helps manage buyer expectations and construction requirements. Used for cost estimation and quality control.

**Traps & Peculiarities:**
- Very simple model with minimal business logic
- No validation on the value/details fields content
- No versioning for specification changes
- No cost impact tracking for custom specifications

**Questions & Suggestions:**
- Add specification templates for standard configurations
- Implement cost calculation for custom specifications
- Add approval workflow for custom specifications
- Consider specification categories/grouping
- Add compatibility validation between specifications

**Useful Information:**
- Type-based categorization
- Standard vs custom differentiation
- Simple and focused scope
- Links specifications to specific lots
- Display name formatting helper

### 14. ProgressReport (`Immo::Promo::ProgressReport`)

**Business Purpose:**
Documents project progress at regular intervals with photos, documents, and narrative updates. Tracks overall progress percentage and identifies issues/risks. Created by project managers for stakeholder communication. Provides historical record of project evolution and decision points.

**Traps & Peculiarities:**
- No validation that report_date isn't in the future
- No template/structure for issues_risks content
- No comparison with previous reports
- Missing approval/review workflow
- No automatic progress calculation from phases/tasks

**Questions & Suggestions:**
- Add report templates for consistency
- Implement automatic progress collection from phases/tasks
- Add comparison/trend analysis with previous reports
- Include weather/site conditions tracking
- Add distribution list for automatic sharing

**Useful Information:**
- Multiple file attachments (photos and documents)
- Issues and risks narrative field
- Period-based filtering for reports
- Prepared by user tracking
- Simple recent/historical classification

### 15. Certification (`Immo::Promo::Certification`)

**Business Purpose:**
Tracks professional certifications, insurance, and qualifications for stakeholders. Includes RGE environmental certifications for energy efficiency work. Monitors expiry dates to ensure compliance. Critical for regulatory compliance and risk management. Validates stakeholder eligibility for specific project roles.

**Traps & Peculiarities:**
- issuing_body aliased to issuing_authority for compatibility
- No notification system for expiring certifications
- No support for certification renewal tracking
- Missing certification requirements by stakeholder type

**Questions & Suggestions:**
- Add automatic expiry notifications
- Implement renewal workflow with reminders
- Add required certifications validation by stakeholder type
- Support for multi-year certifications
- Add certification cost tracking

**Useful Information:**
- Expiry monitoring with status calculation
- Document attachment for certificates
- Type-based categorization
- Validity status helper methods
- Integration with stakeholder validation

### 16. PermitCondition (`Immo::Promo::PermitCondition`)

**Business Purpose:**
Represents conditions attached to approved permits that must be fulfilled for compliance. Includes suspensive conditions that must be met before starting work, prescriptive conditions for how work must be done, and informational requirements. Tracks fulfillment status and deadlines. Critical for maintaining permit validity and avoiding legal issues.

**Traps & Peculiarities:**
- No validation linking due_date to permit expiry
- No notification system for overdue conditions
- No workflow for condition fulfillment review
- Missing link to responsible stakeholder

**Questions & Suggestions:**
- Add responsible party assignment
- Implement notification system for due dates
- Add fulfillment evidence requirements
- Link conditions to specific project phases
- Add cost impact for prescriptive conditions

**Useful Information:**
- Type-based categorization of conditions
- Due date tracking with overdue detection
- Compliance document attachment
- Simple fulfillment boolean flag
- Access to project through permit association

### 17. PhaseDependency (`Immo::Promo::PhaseDependency`)

**Business Purpose:**
Manages dependencies between project phases using standard project management relationships (Finish-to-Start, Start-to-Start, Finish-to-Finish, Start-to-Finish). Includes lag time support for scheduling flexibility. Prevents circular dependencies and ensures phases belong to the same project. Essential for critical path calculation and schedule optimization.

**Traps & Peculiarities:**
- Complex circular dependency detection algorithm
- No validation of dependency type logic (e.g., FS with negative lag)
- No cascade updates when phase dates change
- Missing dependency strength/criticality flag

**Questions & Suggestions:**
- Add dependency constraint enforcement in phase scheduling
- Implement cascade date updates through dependencies
- Add optional/mandatory dependency flag
- Support for multiple dependency types per phase pair
- Add dependency visualization support

**Useful Information:**
- Four standard dependency types
- Lag days support for flexible scheduling
- Circular dependency prevention
- Same-project validation
- Used for critical path analysis

### 18. TaskDependency (`Immo::Promo::TaskDependency`)

**Business Purpose:**
Similar to PhaseDependency but at the task level, enabling fine-grained project scheduling. Supports the same dependency types and lag time. Ensures tasks belong to the same project and prevents circular dependencies. Critical for detailed project planning and resource allocation.

**Traps & Peculiarities:**
- Duplicate code with PhaseDependency (DRY violation)
- No validation that tasks are in sequential phases
- No automatic task date adjustment
- Project comparison might fail with nil values

**Questions & Suggestions:**
- Extract common dependency logic to a concern
- Add cross-phase dependency validation
- Implement automatic schedule adjustment
- Add dependency violation notifications
- Consider soft dependencies for flexibility

**Useful Information:**
- Identical structure to PhaseDependency
- Full dependency type support
- Circular dependency prevention
- Project scope validation
- Lag time support

### 19. TimeLog (`Immo::Promo::TimeLog`)

**Business Purpose:**
Records actual time spent by users on tasks for accurate project costing and progress tracking. Prevents duplicate entries for the same user/task/date combination. Supports period-based reporting for payroll and billing. Essential for comparing estimated vs actual effort and improving future estimates.

**Traps & Peculiarities:**
- Uniqueness constraint might be too restrictive for multiple work sessions
- No validation against task estimated_hours
- No approval workflow for logged time
- Missing billable/non-billable flag
- No rate information for cost calculation

**Questions & Suggestions:**
- Allow multiple logs per day with start/end times
- Add manager approval workflow
- Include hourly rate for cost calculation
- Add work description/notes field
- Implement overtime tracking

**Useful Information:**
- User-task-date uniqueness constraint
- Maximum 24 hours per entry
- Period-based reporting scopes
- Access to project through task association
- Weekly and monthly aggregation scopes

### 20. TimeLog (`Immo::Promo::TimeLog`)

**Business Purpose:**
Records actual time spent by users on tasks for accurate project costing and progress tracking. Prevents duplicate entries for the same user/task/date combination. Supports period-based reporting for payroll and billing. Essential for comparing estimated vs actual effort and improving future estimates.

**Traps & Peculiarities:**
- Uniqueness constraint might be too restrictive for multiple work sessions
- No validation against task estimated_hours
- No approval workflow for logged time
- Missing billable/non-billable flag
- No rate information for cost calculation

**Questions & Suggestions:**
- Allow multiple logs per day with start/end times
- Add manager approval workflow
- Include hourly rate for cost calculation
- Add work description/notes field
- Implement overtime tracking

**Useful Information:**
- User-task-date uniqueness constraint
- Maximum 24 hours per entry
- Period-based reporting scopes
- Access to project through task association
- Weekly and monthly aggregation scopes

### 21. Documentable (Concern)

**Business Purpose:**
Provides document management capabilities to all ImmoPromo models. Integrates with the main application's Document model through polymorphic associations. Supports document categorization, versioning, validation workflows, and sharing with stakeholders. Ensures consistent document handling across all models while maintaining flexibility for model-specific requirements.

**Traps & Peculiarities:**
- Creates spaces/folders automatically which might clutter the system
- Document integration service is referenced but not defined
- Hardcoded 30-day expiry for document shares
- Complex authorization queries that could be slow
- No transaction wrapping for bulk operations

**Questions & Suggestions:**
- Make document share expiry configurable
- Add transaction support for bulk operations
- Implement caching for authorization queries
- Add document templates by model type
- Consider async processing for large uploads

**Useful Information:**
- Full document lifecycle management
- Seven document categories for classification
- Validation workflow integration
- Stakeholder sharing capabilities
- Compliance checking for required documents

## Key Patterns and Recommendations

### 1. Common Issues Across Models
- **I18n**: Several models return French strings instead of using Rails I18n
- **Money Handling**: Inconsistent currency handling, often hardcoded to EUR
- **Validations**: Missing date range validations (start < end)
- **State Machines**: Status fields without proper state transition validation
- **N+1 Queries**: Complex calculations without proper includes/joins

### 2. Reusable Patterns
- **Monetization**: Consistent use of money-rails for financial fields
- **Auditing**: All major models use audited gem
- **Concerns**: Addressable, Schedulable, WorkflowManageable, Documentable
- **Scoping**: Rich scoping patterns for filtering and reporting
- **Status Tracking**: Consistent status enums across models

### 3. Architectural Suggestions
- **Service Layer**: Extract complex calculations into service objects
- **Form Objects**: Use form objects for complex multi-model operations
- **Query Objects**: Extract complex queries for reusability and testing
- **State Machines**: Implement proper state machines for status transitions
- **Event System**: Add domain events for important state changes

### 4. Performance Considerations
- **Counter Caches**: Add for phases_count, tasks_count, etc.
- **Database Indexes**: Review and add indexes for foreign keys and frequently queried fields
- **Eager Loading**: Implement consistent eager loading strategies
- **Caching**: Add caching for expensive calculations
- **Background Jobs**: Move heavy operations to background jobs

### 5. Data Integrity
- **Constraints**: Add database-level constraints for critical validations
- **Transactions**: Wrap multi-model operations in transactions
- **Soft Deletes**: Consider soft deletes for audit trail
- **Versioning**: Expand versioning beyond documents to other models
- **Data Archival**: Plan for historical data archival strategy