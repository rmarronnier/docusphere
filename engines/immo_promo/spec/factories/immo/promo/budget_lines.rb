FactoryBot.define do
  factory :immo_promo_budget_line, class: 'Immo::Promo::BudgetLine' do
    sequence(:name) { |n| "Ligne budgétaire #{n}" }
    category { 'construction' }
    planned_amount_cents { 100_000_00 }
    planned_amount_currency { 'EUR' }
    actual_amount_cents { 0 }
    actual_amount_currency { 'EUR' }
    association :project, factory: :immo_promo_project
    
    trait :construction do
      category { 'construction' }
      name { 'Travaux de construction' }
    end
    
    trait :permits do
      category { 'permits' }
      name { 'Frais de permis' }
      planned_amount_cents { 20_000_00 }
    end
    
    trait :consultancy do
      category { 'consultancy' }
      name { 'Honoraires consultants' }
      planned_amount_cents { 50_000_00 }
    end
    
    trait :overbudget do
      actual_amount_cents { 120_000_00 }
    end
  end
end