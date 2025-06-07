FactoryBot.define do
  factory :project_workflow_step do
    workflowable { nil }
    name { "MyString" }
    description { "MyText" }
    position { 1 }
    status { "MyString" }
    assigned_to { nil }
  end
end
