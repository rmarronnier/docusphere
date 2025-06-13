# Immo::Promo Engine TODO

## ViewComponent Enhancements

### ✅ Completed
- **InterventionCardComponent** - Comprehensive intervention display system with 4 variants
- **Coordination namespace** - Established component organization for coordination features
- **Test Suite** - 39 tests providing 100% coverage for InterventionCardComponent
- **Documentation** - Comprehensive engine summary with architecture analysis

### 🎯 High Priority Component Extractions

#### 1. Financial Dashboard Components
**Location**: `app/views/immo/promo/commercial_dashboard/dashboard.html.erb`

**Opportunities**:
- **RevenueMetricCardComponent** - Extract revenue/sales metric displays (4 similar blocks)
- **CommercialChartComponent** - Standardize chart displays with configuration options
- **SalesProgressComponent** - Unify sales progress visualizations
- **ReservationStatusComponent** - Create flexible reservation status displays

**Impact**: ~120 lines → ~20 lines (83% reduction)

#### 2. Risk Monitoring Components
**Location**: `app/views/immo/promo/risk_monitoring/dashboard.html.erb`

**Opportunities**:
- **RiskAlertCardComponent** - Standardize risk alert displays
- **MitigationProgressComponent** - Track mitigation action progress
- **RiskMatrixComponent** - Interactive risk assessment matrix
- **RiskTimelineComponent** - Risk evolution over time

**Impact**: ~95 lines → ~15 lines (84% reduction)

#### 3. Permit Workflow Components
**Location**: `app/views/immo/promo/permit_workflow/dashboard.html.erb`

**Opportunities**:
- **PermitStatusCardComponent** - Permit application status tracking
- **ComplianceIndicatorComponent** - Regulatory compliance display
- **DeadlineWarningComponent** - Permit deadline alerts
- **DocumentRequirementComponent** - Required document checklist

**Impact**: ~80 lines → ~12 lines (85% reduction)

#### 4. Project Management Components
**Location**: `app/views/immo/promo/projects/show.html.erb`

**Opportunities**:
- **ProjectOverviewComponent** - Project header with key metrics
- **PhaseNavigationComponent** - Project phase navigation tabs
- **StakeholderSummaryComponent** - Key stakeholder information display
- **BudgetSummaryComponent** - Budget overview with variance indicators

**Impact**: ~150 lines → ~25 lines (83% reduction)

### 🔄 Medium Priority Improvements

#### 1. Test Coverage Expansion
**Current**: 132 tests across 11 component files
**Target**: 300+ tests across 25+ component files
**Priority Components Needing Tests**:
- Document components (4 components, 0 tests)
- Navbar components (7 components, 0 tests) 
- Remaining timeline components (5 components, 8 tests)

#### 2. Component API Enhancements
**Standardization Opportunities**:
- **Size variants**: Ensure all components support `:small`, `:medium`, `:large`
- **Theme variants**: Add consistent color schemes across components
- **Loading states**: Add loading/skeleton state support
- **Error states**: Standardize error display patterns

#### 3. Performance Optimizations
**Caching Strategy**:
- Add fragment caching to expensive components
- Implement component-level caching for static data
- Optimize CSS class generation
- Add lazy loading for complex components

### 🚀 Low Priority Enhancements

#### 1. Advanced Features
- **Responsive breakpoints**: Fine-tune mobile/tablet/desktop layouts
- **Accessibility**: Add ARIA labels, keyboard navigation, screen reader support
- **Internationalization**: Extract hardcoded French strings to i18n files
- **Dark mode support**: Add theme switching capabilities

#### 2. Developer Experience
- **Component generator**: Create rake task for new component scaffolding
- **Lookbook integration**: Add component preview system
- **Style guide**: Document component usage patterns
- **Performance monitoring**: Add component render time tracking

#### 3. Integration Improvements
- **Main app sharing**: Share common components between app and engine
- **Cross-engine reuse**: Enable component sharing between engines
- **Design tokens**: Standardize spacing, colors, typography
- **Theme system**: Centralized styling configuration

## Technical Debt & Maintenance

### 🧹 Code Quality Issues

#### 1. Missing Tests
**Files needing test coverage**:
```
engines/immo_promo/app/components/immo/promo/documents/
├── bulk_upload_component.rb (0% coverage)
├── document_list_component.rb (0% coverage)
├── document_status_component.rb (0% coverage)
└── document_upload_component.rb (0% coverage)

engines/immo_promo/app/components/immo/promo/navbar/
├── logo_component.rb (0% coverage)
├── mobile_menu_component.rb (0% coverage)
├── navigation_component.rb (0% coverage)
├── new_project_button_component.rb (0% coverage)
├── new_project_modal_component.rb (0% coverage)
└── project_actions_component.rb (0% coverage)
```

#### 2. Documentation Gaps
- Component parameter documentation
- Usage examples in component files
- Integration guidelines
- Migration documentation for new components

#### 3. Consistency Issues
- Mixed parameter naming conventions
- Inconsistent CSS class generation patterns
- Varying error handling approaches
- Different testing patterns across components

### 🔧 Infrastructure Improvements

#### 1. Build System
- **Component bundling**: Optimize component loading
- **CSS purging**: Remove unused styles in production
- **Asset optimization**: Minimize component-specific assets
- **Hot reloading**: Improve development experience

#### 2. Monitoring & Analytics
- **Component usage tracking**: Identify unused components
- **Performance metrics**: Track render times and memory usage
- **Error reporting**: Centralized component error handling
- **A/B testing**: Component variant testing framework

## Implementation Roadmap

### Sprint 1: Test Coverage Boost
- [ ] Add tests for all Document components (4 components)
- [ ] Add tests for Navbar components (7 components)  
- [ ] Achieve 80% overall test coverage
- [ ] Fix any discovered bugs during testing

### Sprint 2: Financial Dashboard Components
- [ ] Extract RevenueMetricCardComponent
- [ ] Create CommercialChartComponent
- [ ] Build SalesProgressComponent
- [ ] Implement ReservationStatusComponent
- [ ] Full test coverage for new components

### Sprint 3: Risk & Permit Components
- [ ] Extract RiskAlertCardComponent
- [ ] Create PermitStatusCardComponent
- [ ] Build ComplianceIndicatorComponent
- [ ] Implement DeadlineWarningComponent
- [ ] Performance optimization pass

### Sprint 4: Performance & Polish
- [ ] Add component-level caching
- [ ] Implement lazy loading
- [ ] Accessibility improvements
- [ ] Documentation completion
- [ ] Lookbook integration

## Success Metrics

### 📊 Key Performance Indicators

**Code Quality**:
- Test coverage: 65% → 90%
- Template complexity: Reduce by 80% in targeted views
- Component reuse: 5+ components used in multiple contexts

**Developer Experience**:
- Component creation time: <30 minutes for standard components
- Bug fix time: Reduced by 50% for UI issues
- Onboarding time: New developers productive in <2 days

**Performance**:
- Page load times: 10% improvement on dashboard pages
- Memory usage: 15% reduction in view rendering
- Cache hit ratio: >80% for static components

**Maintenance**:
- Code duplication: <5% in view templates
- Design consistency: 100% adherence to component patterns
- Regression rate: <1% for component changes

---

*Last updated: June 13, 2025*
*Next review: July 1, 2025*