FactoryBot.define do
  factory :immo_promo_project, class: 'Immo::Promo::Project' do
    association :organization
    association :project_manager, factory: :user
    sequence(:name) { |n| "Projet #{n}" }
    sequence(:reference) { |n| "PROJ-#{n.to_s.rjust(4, '0')}" }
    description { "Description du projet immobilier" }
    project_type { 'residential' }
    status { 'planning' }
    start_date { Date.current }
    end_date { Date.current + 2.years }
    address { "123 Rue de la Paix" }
    city { "Paris" }
    postal_code { "75001" }
    country { "France" }
    total_budget_cents { 500_000_000 }

    trait :development do
      status { 'development' }
    end

    trait :completed do
      status { 'completed' }
    end

    trait :commercial do
      project_type { 'commercial' }
    end

    trait :with_phases do
      after(:create) do |project|
        create_list(:immo_promo_phase, 3, project: project)
      end
    end
  end

  factory :immo_promo_phase, class: 'Immo::Promo::Phase' do
    association :project, factory: :immo_promo_project
    sequence(:name) { |n| "Phase #{n}" }
    phase_type { 'studies' }
    status { 'pending' }
    sequence(:position) { |n| n }
    start_date { Date.current }
    end_date { Date.current + 3.months }
    description { "Description de la phase" }

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :completed do
      status { 'completed' }
    end

    trait :construction do
      phase_type { 'construction' }
    end

    trait :with_tasks do
      after(:create) do |phase|
        create_list(:immo_promo_task, 2, phase: phase)
      end
    end
  end

  factory :immo_promo_task, class: 'Immo::Promo::Task' do
    association :phase, factory: :immo_promo_phase
    association :assigned_to, factory: :user
    association :stakeholder, factory: :immo_promo_stakeholder
    sequence(:name) { |n| "Tâche #{n}" }
    description { "Description de la tâche" }
    task_type { 'technical' }
    priority { 'medium' }
    status { 'pending' }
    start_date { Date.current }
    end_date { Date.current + 1.week }
    estimated_hours { 40 }
    estimated_cost_cents { 10_000_00 }

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :completed do
      status { 'completed' }
    end

    trait :high_priority do
      priority { 'high' }
    end
  end

  factory :immo_promo_stakeholder, class: 'Immo::Promo::Stakeholder' do
    association :project, factory: :immo_promo_project
    sequence(:name) { |n| "Entreprise #{n}" }
    stakeholder_type { 'contractor' }
    sequence(:email) { |n| "contact#{n}@entreprise.fr" }
    phone { "01 23 45 67 89" }
    address { "456 Avenue des Professionnels" }
    city { "Paris" }
    postal_code { "75002" }
    country { "France" }
    is_active { true }

    trait :architect do
      stakeholder_type { 'architect' }
    end

    trait :engineer do
      stakeholder_type { 'engineer' }
    end

    trait :inactive do
      is_active { false }
    end
  end

  factory :immo_promo_contract, class: 'Immo::Promo::Contract' do
    association :project, factory: :immo_promo_project
    association :stakeholder, factory: :immo_promo_stakeholder
    sequence(:reference) { |n| "CONT-#{n.to_s.rjust(4, '0')}" }
    contract_type { 'service' }
    status { 'draft' }
    start_date { Date.current }
    end_date { Date.current + 1.year }
    amount_cents { 100_000_00 }
    description { "Contrat de prestation" }

    trait :signed do
      status { 'signed' }
      signed_at { Date.current }
    end

    trait :works do
      contract_type { 'works' }
    end
  end

  factory :immo_promo_permit, class: 'Immo::Promo::Permit' do
    association :project, factory: :immo_promo_project
    sequence(:reference) { |n| "PC-#{n.to_s.rjust(6, '0')}" }
    permit_type { 'building_permit' }
    status { 'pending' }
    application_date { Date.current }
    expected_response_date { Date.current + 3.months }
    description { "Demande de permis de construire" }

    trait :approved do
      status { 'approved' }
      approval_date { Date.current }
    end

    trait :environmental do
      permit_type { 'environmental' }
    end
  end

  factory :immo_promo_budget, class: 'Immo::Promo::Budget' do
    association :project, factory: :immo_promo_project
    sequence(:name) { |n| "Budget v#{n}" }
    budget_type { 'initial' }
    status { 'draft' }
    total_amount_cents { 500_000_000 }
    description { "Budget prévisionnel du projet" }
    created_at { Date.current }

    trait :approved do
      status { 'approved' }
    end

    trait :revised do
      budget_type { 'revised' }
    end

    trait :with_lines do
      after(:create) do |budget|
        create_list(:immo_promo_budget_line, 3, budget: budget)
      end
    end
  end

  factory :immo_promo_budget_line, class: 'Immo::Promo::BudgetLine' do
    association :budget, factory: :immo_promo_budget
    sequence(:name) { |n| "Poste #{n}" }
    category { 'studies' }
    amount_cents { 50_000_00 }
    description { "Ligne budgétaire" }

    trait :construction do
      category { 'construction' }
    end

    trait :equipment do
      category { 'equipment' }
    end
  end

  factory :immo_promo_lot, class: 'Immo::Promo::Lot' do
    association :project, factory: :immo_promo_project
    sequence(:reference) { |n| "LOT-#{n.to_s.rjust(3, '0')}" }
    lot_type { 'apartment' }
    floor_level { 1 }
    surface_area { 65.5 }
    rooms_count { 3 }
    base_price_cents { 250_000_00 }
    status { 'planned' }
    description { "Appartement T3" }

    trait :reserved do
      status { 'reserved' }
    end

    trait :sold do
      status { 'sold' }
    end

    trait :house do
      lot_type { 'house' }
      surface_area { 120.0 }
      rooms_count { 5 }
    end
  end

  factory :immo_promo_risk_assessment, class: 'Immo::Promo::RiskAssessment' do
    association :project, factory: :immo_promo_project
    risk_category { 'technical' }
    risk_type { 'delay' }
    description { "Risque de retard sur les travaux" }
    probability { 3 }
    impact { 4 }
    mitigation_plan { "Plan de mitigation des risques" }
    status { 'active' }

    trait :financial do
      risk_category { 'financial' }
    end

    trait :mitigated do
      status { 'mitigated' }
    end
  end

  factory :immo_promo_progress_report, class: 'Immo::Promo::ProgressReport' do
    association :project, factory: :immo_promo_project
    association :created_by, factory: :user
    report_date { Date.current }
    overall_progress { 45.5 }
    summary { "Résumé d'avancement du projet" }
    key_achievements { "Réalisations clés de la période" }
    upcoming_milestones { "Jalons à venir" }
    issues_risks { "Problèmes et risques identifiés" }
  end
  
  factory :immo_promo_phase_dependency, class: 'Immo::Promo::PhaseDependency' do
    association :dependent_phase, factory: :immo_promo_phase
    association :prerequisite_phase, factory: :immo_promo_phase
  end
  
  factory :immo_promo_milestone, class: 'Immo::Promo::Milestone' do
    association :project, factory: :immo_promo_project
    association :phase, factory: :immo_promo_phase
    sequence(:name) { |n| "Jalon #{n}" }
    milestone_type { 'permit_submission' }
    status { 'pending' }
    target_date { Date.current + 3.months }
    is_critical { false }
    
    trait :critical do
      is_critical { true }
    end
    
    trait :completed do
      status { 'completed' }
      actual_date { Date.current }
      completed_at { Time.current }
    end
    
    trait :overdue do
      target_date { Date.current - 1.week }
    end
  end
  
  factory :immo_promo_time_log, class: 'Immo::Promo::TimeLog' do
    association :task, factory: :immo_promo_task
    association :user
    hours { 4.5 }
    log_date { Date.current }
    description { "Travail effectué sur la tâche" }
  end
  
  factory :immo_promo_task_dependency, class: 'Immo::Promo::TaskDependency' do
    association :prerequisite_task, factory: :immo_promo_task
    association :dependent_task, factory: :immo_promo_task
    dependency_type { 'finish_to_start' }
    lag_days { 0 }
  end
end