FactoryBot.define do
  factory :immo_promo_risk, class: 'Immo::Promo::Risk' do
    association :project, factory: :immo_promo_project
    association :identified_by, factory: :user
    sequence(:name) { |n| "Risque #{n}" }
    risk_type { 'technical' }
    severity { 'medium' }
    probability { 'possible' }
    status { 'active' }
    description { 'Description du risque' }
    impact_description { 'Impact potentiel' }
    
    trait :high_risk do
      severity { 'high' }
      probability { 'likely' }
    end
    
    trait :mitigated do
      status { 'mitigated' }
      mitigation_plan { 'Plan de mitigation' }
      association :mitigated_by, factory: :user
      mitigation_date { 1.week.ago }
    end
  end
end