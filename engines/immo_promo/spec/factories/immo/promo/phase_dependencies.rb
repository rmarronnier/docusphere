FactoryBot.define do
  factory :immo_promo_phase_dependency, class: 'Immo::Promo::PhaseDependency' do
    dependency_type { 'finish_to_start' }
    
    after(:build) do |phase_dependency|
      project = create(:immo_promo_project)
      phase_dependency.prerequisite_phase ||= create(:immo_promo_phase, project: project, position: 1)
      phase_dependency.dependent_phase ||= create(:immo_promo_phase, project: project, position: 2)
    end
  end
end