FactoryBot.define do
  factory :document_validation do
    association :validatable, factory: :document
    validator { association :user }
    validation_request { association :validation_request, validatable: validatable }
    status { 'pending' }
    comment { nil }
    validated_at { nil }
    
    trait :approved do
      status { 'approved' }
      comment { 'Document approved' }
      validated_at { Time.current }
    end
    
    trait :rejected do
      status { 'rejected' }
      comment { 'Issues found, document rejected' }
      validated_at { Time.current }
    end
  end
end
