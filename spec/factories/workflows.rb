FactoryBot.define do
  factory :workflow do
    sequence(:name) { |n| "Workflow #{n}" }
    description { "Description du workflow" }
    organization
    
    trait :active do
      status { 'active' }
    end
    
    trait :completed do
      status { 'completed' }
    end
    
    trait :cancelled do
      status { 'cancelled' }
    end
    
    trait :paused do
      status { 'paused' }
    end
    
    trait :with_steps do
      after(:create) do |workflow|
        create_list(:workflow_step, 3, workflow: workflow)
      end
    end
  end
  
  factory :workflow_step do
    workflow
    sequence(:name) { |n| "Étape #{n}" }
    description { "Description de l'étape" }
    step_type { "manual" }
    sequence(:position) { |n| n }
    association :assigned_to, factory: :user
    validation_rules { {} }
  end
end