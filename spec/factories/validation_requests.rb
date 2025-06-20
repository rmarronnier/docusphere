FactoryBot.define do
  factory :validation_request do
    association :validatable, factory: :document
    requester { association :user }
    min_validations { 1 }
    status { 'pending' }
    completed_at { nil }
    
    transient do
      validators { [] }
    end
    
    after(:create) do |validation_request, evaluator|
      if evaluator.validators.any?
        # Créer directement les document_validations sans passer par add_validators
        # pour éviter les notifications automatiques dans les tests
        evaluator.validators.each do |validator|
          validation_request.document_validations.create!(
            validatable: validation_request.validatable,
            validator: validator,
            status: 'pending'
          )
        end
      end
    end
    
    trait :with_validators do
      transient do
        validator_count { 2 }
      end
      
      after(:create) do |validation_request, evaluator|
        create_list(:document_validation, evaluator.validator_count, 
          validatable: validation_request.validatable,
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