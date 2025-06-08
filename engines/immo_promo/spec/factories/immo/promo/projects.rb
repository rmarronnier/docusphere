FactoryBot.define do
  factory :immo_promo_project, class: 'Immo::Promo::Project' do
    sequence(:name) { |n| "Projet #{n}" }
    sequence(:reference_number) { |n| "REF-#{n.to_s.rjust(4, '0')}" }
    project_type { 'residential' }
    status { 'planning' }
    association :organization
    association :project_manager, factory: :user
    start_date { Date.current }
    expected_completion_date { Date.current + 2.years }
    total_budget_cents { 5_000_000_00 }
    description { "Description du projet" }

    trait :with_phases do
      after(:create) do |project|
        create_list(:immo_promo_phase, 3, project: project)
      end
    end

    trait :commercial do
      project_type { 'commercial' }
      total_budget_cents { 10_000_000_00 }
    end

    trait :in_construction do
      status { 'construction' }
    end

    trait :completed do
      status { 'completed' }
      actual_completion_date { Date.current }
    end
  end
end
