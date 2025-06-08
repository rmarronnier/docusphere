FactoryBot.define do
  factory :immo_promo_budget_line, class: 'Immo::Promo::BudgetLine' do
    category { 'construction_work' }
    description { 'Construction costs' }
    planned_amount_cents { 100_000_00 }
    actual_amount_cents { 0 }
    association :budget, factory: :immo_promo_budget

    trait :construction do
      category { 'construction_work' }
      description { 'Travaux de construction' }
    end

    trait :permits do
      category { 'administrative' }
      description { 'Frais de permis' }
      planned_amount_cents { 20_000_00 }
    end

    trait :consultancy do
      category { 'studies' }
      description { 'Honoraires consultants' }
      planned_amount_cents { 50_000_00 }
    end

    trait :overbudget do
      actual_amount_cents { 120_000_00 }
    end
  end
end
