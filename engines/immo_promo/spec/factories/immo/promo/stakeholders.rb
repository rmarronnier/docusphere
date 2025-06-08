FactoryBot.define do
  factory :immo_promo_stakeholder, class: 'Immo::Promo::Stakeholder' do
    sequence(:name) { |n| "Partie prenante #{n}" }
    stakeholder_type { 'contractor' }
    sequence(:email) { |n| "stakeholder#{n}@example.com" }
    phone { '+33 1 23 45 67 89' }
    company_name { 'Entreprise Test' }
    contact_person { 'Jean Dupont' }
    is_active { true }
    association :project, factory: :immo_promo_project

    trait :inactive do
      is_active { false }
    end

    trait :architect do
      stakeholder_type { 'architect' }
      company_name { 'Cabinet Architecture Plus' }
    end

    trait :contractor do
      stakeholder_type { 'contractor' }
      company_name { 'Construction Pro' }
    end

    trait :promoter do
      stakeholder_type { 'promoter' }
      company_name { 'Immobilier Dev' }
    end

    trait :investor do
      stakeholder_type { 'investor' }
      company_name { 'Invest Capital' }
    end

    trait :consultant do
      stakeholder_type { 'consultant' }
      company_name { 'Conseil Expert' }
    end
  end
end
