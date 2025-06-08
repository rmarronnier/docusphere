FactoryBot.define do
  factory :immo_promo_phase_dependency, class: 'Immo::Promo::PhaseDependency' do
    association :prerequisite_phase, factory: :immo_promo_phase
    association :dependent_phase, factory: :immo_promo_phase
    dependency_type { 'finish_to_start' }
  end
end