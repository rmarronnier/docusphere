FactoryBot.define do
  factory :immo_promo_lot, class: 'Immo::Promo::Lot' do
    sequence(:lot_number) { |n| "LOT-#{n.to_s.rjust(3, '0')}" }
    lot_type { 'apartment' }
    floor { 1 }
    surface_area { 75.5 }
    price_cents { 350_000_00 }
    price_currency { 'EUR' }
    status { 'available' }
    association :project, factory: :immo_promo_project
    
    trait :apartment do
      lot_type { 'apartment' }
      surface_area { 75.5 }
    end
    
    trait :parking do
      lot_type { 'parking' }
      surface_area { 12.5 }
      price_cents { 25_000_00 }
    end
    
    trait :storage do
      lot_type { 'storage' }
      surface_area { 5.0 }
      price_cents { 10_000_00 }
    end
    
    trait :reserved do
      status { 'reserved' }
    end
    
    trait :sold do
      status { 'sold' }
    end
  end
end