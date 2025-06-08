FactoryBot.define do
  factory :validation_request do
    document
    requester { association :user }
    min_validations { 1 }
    status { 'pending' }
    completed_at { nil }
    
    trait :with_validators do
      transient do
        validator_count { 2 }
      end
      
      after(:create) do |validation_request, evaluator|
        create_list(:document_validation, evaluator.validator_count, 
          document: validation_request.document,
          validation_request: validation_request
        )
      end
    end
    
    trait :approved do
      status { 'approved' }
      completed_at { Time.current }
    end
    
    trait :rejected do
      status { 'rejected' }
      completed_at { Time.current }
    end
  end
end
