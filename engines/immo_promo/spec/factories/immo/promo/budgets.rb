FactoryBot.define do
  factory :immo_promo_budget, class: 'Immo::Promo::Budget' do
    association :project, factory: :immo_promo_project
    name { 'Budget Principal' }
    budget_type { 'initial' }
    total_amount_cents { 500_000_00 }  # 500,000.00 EUR in cents
    spent_amount_cents { 0 }
    status { 'approved' }
    version { 1 }
    is_current { true }
    
    trait :revised do
      budget_type { 'revised' }
      total_amount_cents { 550_000_00 }  # 550,000.00 EUR in cents
      version { 2 }
    end
    
    trait :final do
      budget_type { 'final' }
      total_amount_cents { 520_000_00 }  # 520,000.00 EUR in cents
      version { 3 }
    end
  end
end