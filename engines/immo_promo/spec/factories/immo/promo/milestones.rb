FactoryBot.define do
  factory :immo_promo_milestone, class: 'Immo::Promo::Milestone' do
    association :phase, factory: :immo_promo_phase
    sequence(:name) { |n| "Jalon #{n}" }
    milestone_type { 'delivery' }
    target_date { 1.month.from_now }
    status { 'pending' }
    is_critical { false }
    description { 'Description du jalon' }
    
    trait :completed do
      status { 'completed' }
      actual_date { Date.current }
      completed_at { Time.current }
    end
    
    trait :critical do
      is_critical { true }
    end
    
    # For tests that expect project directly, build phase with project
    transient do
      project { nil }
    end
    
    after(:build) do |milestone, evaluator|
      if evaluator.project && !milestone.phase
        milestone.phase = build(:immo_promo_phase, project: evaluator.project)
      elsif evaluator.project && milestone.phase && !milestone.phase.project
        milestone.phase.project = evaluator.project
      end
    end
  end
end