FactoryBot.define do
  factory :immo_promo_task_dependency, class: 'Immo::Promo::TaskDependency' do
    association :prerequisite_task, factory: :immo_promo_task
    association :dependent_task, factory: :immo_promo_task
    dependency_type { 'finish_to_start' }
  end
end