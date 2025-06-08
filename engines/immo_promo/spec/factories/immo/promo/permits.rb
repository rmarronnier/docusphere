FactoryBot.define do
  factory :immo_promo_permit, class: 'Immo::Promo::Permit' do
    sequence(:permit_number) { |n| "PC-2024-#{n.to_s.rjust(4, '0')}" }
    permit_type { 'building' }
    status { 'submitted' }
    issuing_authority { 'Mairie de Paris' }
    submitted_date { Date.current }
    expected_date { Date.current + 3.months }
    association :project, factory: :immo_promo_project
    
    trait :building do
      permit_type { 'building' }
      description { 'Permis de construire' }
    end
    
    trait :demolition do
      permit_type { 'demolition' }
      description { 'Permis de démolir' }
    end
    
    trait :environmental do
      permit_type { 'environmental' }
      description { 'Autorisation environnementale' }
    end
    
    trait :approved do
      status { 'approved' }
      approval_date { Date.current }
      expiry_date { Date.current + 2.years }
    end
    
    trait :rejected do
      status { 'rejected' }
      approval_date { Date.current }
    end
  end
end