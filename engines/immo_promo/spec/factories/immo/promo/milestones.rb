FactoryBot.define do
  factory :immo_promo_milestone, class: 'Immo::Promo::Milestone' do
    association :project, factory: :immo_promo_project
    association :phase, factory: :immo_promo_phase
    sequence(:name) { |n| "Jalon #{n}" }
    milestone_type { 'delivery' }
    target_date { 1.month.from_now }
    status { 'pending' }
    is_critical { false }
    description { 'Description du jalon' }
    
    trait :achieved do
      status { 'achieved' }
      achieved_date { Date.current }
    end
    
    trait :critical do
      is_critical { true }
    end
  end
end