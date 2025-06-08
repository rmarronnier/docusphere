FactoryBot.define do
  factory :immo_promo_contract, class: 'Immo::Promo::Contract' do
    association :project, factory: :immo_promo_project
    association :stakeholder, factory: :immo_promo_stakeholder
    sequence(:contract_number) { |n| "CONT-#{n.to_s.rjust(3, '0')}" }
    contract_type { 'consulting' }
    status { 'draft' }
    start_date { Date.current }
    end_date { Date.current + 6.months }
    amount_cents { 100_000_00 }
    description { 'Contrat de prestation' }
    
    trait :active do
      status { 'active' }
      signed_date { 1.week.ago }
    end
    
    trait :completed do
      status { 'completed' }
      paid_amount_cents { 98_000_00 }
    end
    
    trait :expired do
      status { 'completed' }
      start_date { 7.months.ago }
      end_date { 1.month.ago }
      signed_date { 7.months.ago }
    end
  end
end