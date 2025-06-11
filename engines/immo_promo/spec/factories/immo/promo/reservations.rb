FactoryBot.define do
  factory :immo_promo_reservation, class: 'Immo::Promo::Reservation' do
    client_name { 'Jean Martin' }
    client_email { 'jean.martin@example.com' }
    client_phone { '+33 6 12 34 56 78' }
    reservation_date { Date.current }
    deposit_amount_cents { 5_000_00 }
    # final_price is handled by the lot association
    expiry_date { Date.current + 1.month }
    status { 'pending' }
    association :lot, factory: :immo_promo_lot

    trait :active do
      status { 'active' }
    end

    trait :confirmed do
      status { 'confirmed' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end
    
    trait :expired do
      status { 'expired' }
    end
    
    trait :expiring_soon do
      expiry_date { 3.days.from_now }
      status { 'active' }
    end
  end
end