FactoryBot.define do
  factory :project_workflow_transition do
    association :workflowable, factory: :immo_promo_project
    association :from_step, factory: :project_workflow_step
    association :to_step, factory: :project_workflow_step
    association :transitioned_by, factory: :user
    notes { "Transition note" }
    transitioned_at { Time.current }
  end
end
