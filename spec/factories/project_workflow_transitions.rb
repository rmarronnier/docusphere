FactoryBot.define do
  factory :project_workflow_transition do
    workflowable { nil }
    from_status { "MyString" }
    to_status { "MyString" }
    user { nil }
    comment { "MyText" }
    transitioned_at { "2025-06-07 13:41:45" }
  end
end
