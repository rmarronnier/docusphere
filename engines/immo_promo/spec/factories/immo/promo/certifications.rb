FactoryBot.define do
  factory :immo_promo_certification, class: 'Immo::Promo::Certification' do
    association :project, factory: :immo_promo_project
    name { 'Certification HQE' }
    certification_type { 'environmental' }
    issuing_body { 'Certivéa' }
    status { 'in_progress' }
    target_level { 'Excellent' }
    
    trait :obtained do
      status { 'obtained' }
      obtained_date { Date.current }
      certificate_number { 'HQE-2024-001' }
      expiry_date { 5.years.from_now }
    end
  end
end