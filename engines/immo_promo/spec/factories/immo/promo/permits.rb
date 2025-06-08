FactoryBot.define do
  factory :immo_promo_permit, class: 'Immo::Promo::Permit' do
    sequence(:permit_number) { |n| "PC-2024-#{n.to_s.rjust(4, '0')}" }
    sequence(:name) { |n| "Permis test #{n}" }
    permit_type { 'construction' }
    status { 'submitted' }
    issuing_authority { 'Mairie de Paris' }
    submitted_date { Date.current }
    expiry_date { Date.current + 2.years }
    expected_approval_date { Date.current + 3.months }
    cost { 1500.00 }
    association :project, factory: :immo_promo_project

    trait :construction do
      permit_type { 'construction' }
      description { 'Permis de construire' }
    end

    trait :urban_planning do
      permit_type { 'urban_planning' }
      description { 'Permis d\'urbanisme' }
    end

    trait :demolition do
      permit_type { 'demolition' }
      description { 'Permis de démolir' }
    end

    trait :environmental do
      permit_type { 'environmental' }
      description { 'Autorisation environnementale' }
    end

    trait :modification do
      permit_type { 'modification' }
      description { 'Permis de modification' }
    end

    trait :declaration do
      permit_type { 'declaration' }
      description { 'Déclaration préalable' }
    end

    trait :approved do
      status { 'approved' }
      approval_date { Date.current }
      expiry_date { Date.current + 2.years }
    end

    trait :denied do
      status { 'denied' }
      approval_date { Date.current }
    end

    trait :under_review do
      status { 'under_review' }
    end
  end
end