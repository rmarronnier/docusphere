FactoryBot.define do
  factory :immo_promo_reservation, class: 'Immo::Promo::Reservation' do
    sequence(:reservation_number) { |n| "RES-2024-#{n.to_s.rjust(4, '0')}" }
    client_name { 'Jean Martin' }
    client_email { 'jean.martin@example.com' }
    client_phone { '+33 6 12 34 56 78' }
    reservation_date { Date.current }
    deposit_amount_cents { 5_000_00 }
    deposit_amount_currency { 'EUR' }
    expiry_date { Date.current + 1.month }
    status { 'pending' }
    association :lot, factory: :immo_promo_lot
    association :sales_agent, factory: :user

    trait :confirmed do
      status { 'confirmed' }
      confirmation_date { Date.current }
    end

    trait :cancelled do
      status { 'cancelled' }
      cancellation_date { Date.current }
      cancellation_reason { 'Client désistement' }
    end

    trait :converted do
      status { 'converted' }
      sale_date { Date.current }
    end
  end
end
