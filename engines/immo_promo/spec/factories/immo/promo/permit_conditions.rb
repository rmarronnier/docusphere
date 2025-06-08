FactoryBot.define do
  factory :immo_promo_permit_condition, class: 'Immo::Promo::PermitCondition' do
    association :permit, factory: :immo_promo_permit
    sequence(:description) { |n| "Condition #{n}" }
    condition_type { 'prescriptive' }
    is_fulfilled { false }
    due_date { 1.month.from_now }
    
    trait :met do
      is_fulfilled { true }
      met_date { Date.current }
    end
  end
end