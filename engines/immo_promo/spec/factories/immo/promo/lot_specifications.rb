FactoryBot.define do
  factory :immo_promo_lot_specification, class: 'Immo::Promo::LotSpecification' do
    association :lot, factory: :immo_promo_lot
    sequence(:name) { |n| "Spécification #{n}" }
    category { 'kitchen' }
    description { 'Cuisine équipée haut de gamme' }
    standard_value { 'Standard' }
    
    trait :upgraded do
      upgraded { true }
      upgraded_value { 'Premium' }
      upgrade_cost_cents { 15_000_00 }
    end
  end
end