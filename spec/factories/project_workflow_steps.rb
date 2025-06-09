FactoryBot.define do
  factory :project_workflow_step do
    name { "Design Phase" }
    description { "Initial design and planning" }
    sequence(:sequence_number) { |n| n }
    requires_approval { false }
    is_active { true }
    organization
  end
end
