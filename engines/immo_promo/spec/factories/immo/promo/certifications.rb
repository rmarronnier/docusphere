FactoryBot.define do
  factory :immo_promo_certification, class: 'Immo::Promo::Certification' do
    association :stakeholder, factory: :immo_promo_stakeholder
    name { 'Certification Professionnelle' }
    certification_type { 'qualification' }
    issuing_body { 'Ordre des Architectes' }
    issue_date { 1.year.ago }
    expiry_date { 2.years.from_now }
    is_valid { true }
    
    trait :expired do
      issue_date { 3.years.ago }
      expiry_date { 1.month.ago }
      is_valid { false }
    end
    
    trait :environmental do
      name { 'Certification HQE' }
      certification_type { 'environmental' }
      issuing_body { 'Certivéa' }
    end
  end
end