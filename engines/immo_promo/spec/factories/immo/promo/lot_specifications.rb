FactoryBot.define do
  factory :immo_promo_lot_specification, class: 'Immo::Promo::LotSpecification' do
    association :lot, factory: :immo_promo_lot
    rooms { 3 }
    bedrooms { 2 }
    bathrooms { 1 }
    has_balcony { true }
    has_terrace { false }
    has_parking { true }
    has_storage { true }
    energy_class { "B" }
    accessibility_features { false }
    category { "apartment" }
  end
end