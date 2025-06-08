FactoryBot.define do
  factory :immo_promo_phase, class: 'Immo::Promo::Phase' do
    sequence(:name) { |n| "Phase #{n}" }
    phase_type { 'studies' }
    sequence(:position) { |n| n }
    start_date { Date.current }
    end_date { Date.current + 3.months }
    association :project, factory: :immo_promo_project

    trait :studies do
      phase_type { 'studies' }
      name { 'Planification préliminaires' }
    end

    trait :permits do
      phase_type { 'permits' }
      name { 'Obtention des permis' }
    end

    trait :construction do
      phase_type { 'construction' }
      name { 'Construction' }
    end

    trait :delivery do
      phase_type { 'delivery' }
      name { 'Livraison' }
    end

    trait :completed do
      status { 'completed' }
      actual_end_date { Date.current }
    end
  end
end
