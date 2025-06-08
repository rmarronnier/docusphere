FactoryBot.define do
  factory :immo_promo_mitigation_action, class: 'Immo::Promo::MitigationAction' do
    association :risk, factory: :immo_promo_risk
    action_type { 'preventive' }
    description { 'Action préventive pour réduire la probabilité' }
    association :responsible, factory: :immo_promo_stakeholder
    status { 'planned' }
    due_date { 1.month.from_now }
    cost_estimate_cents { 10_000_00 }
    effectiveness_estimate { 80 }
    
    trait :corrective do
      action_type { 'corrective' }
      description { 'Action corrective pour réduire l\'impact' }
    end
    
    trait :in_progress do
      status { 'in_progress' }
      start_date { 1.week.ago }
    end
    
    trait :completed do
      status { 'completed' }
      start_date { 1.month.ago }
      completion_date { 1.day.ago }
      actual_cost_cents { 9_500_00 }
      effectiveness_achieved { 85 }
      completion_notes { 'Action complétée avec succès' }
    end
  end
end