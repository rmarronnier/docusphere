FactoryBot.define do
  factory :immo_promo_budget, class: 'Immo::Promo::Budget' do
    association :project, factory: :immo_promo_project
    name { 'Budget Principal' }
    budget_type { 'initial' }
    total_amount_cents { 5_000_000_00 }
    status { 'approved' }
    version { 1 }
    
    trait :revised do
      budget_type { 'revised' }
      total_amount_cents { 5_500_000_00 }
    end
  end
end