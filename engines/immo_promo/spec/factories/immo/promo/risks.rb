FactoryBot.define do
  factory :immo_promo_risk, class: 'Immo::Promo::Risk' do
    association :project, factory: :immo_promo_project
    association :owner, factory: :user
    sequence(:title) { |n| "Risque #{n}" }
    category { 'technical' }
    probability { 'medium' }
    impact { 'medium' }
    status { 'identified' }
    description { 'Description du risque' }
    
    trait :high_risk do
      probability { 'high' }
      impact { 'high' }
    end
    
    trait :mitigated do
      status { 'mitigated' }
      mitigation_plan { 'Plan de mitigation' }
    end
  end
end