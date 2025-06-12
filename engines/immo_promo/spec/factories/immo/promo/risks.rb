FactoryBot.define do
  factory :immo_promo_risk, class: 'Immo::Promo::Risk' do
    association :project, factory: :immo_promo_project
    association :owner, factory: :user
    sequence(:title) { |n| "Risque #{n}" }
    category { 'technical' }
    probability { 3 }  # medium value
    impact { 3 }       # medium value
    status { 'identified' }
    description { 'Description du risque' }
    
    trait :high_risk do
      probability { 4 }  # high value
      impact { 4 }       # high value
    end
    
    trait :mitigated do
      status { 'mitigated' }
      mitigation_plan { 'Plan de mitigation' }
    end
  end
end