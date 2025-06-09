FactoryBot.define do
  factory :immo_promo_task_dependency, class: 'Immo::Promo::TaskDependency' do
    dependency_type { 'finish_to_start' }
    
    after(:build) do |task_dependency|
      phase = create(:immo_promo_phase)
      task_dependency.prerequisite_task ||= create(:immo_promo_task, phase: phase)
      task_dependency.dependent_task ||= create(:immo_promo_task, phase: phase)
    end
  end
end