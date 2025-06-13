FactoryBot.define do
  factory :client_relationship do
    association :client
    association :organization
    relationship_type { 'managed' }
    
    trait :managed do
      relationship_type { 'managed' }
    end
    
    trait :prospect do
      relationship_type { 'prospect' }
    end
    
    trait :partner do
      relationship_type { 'partner' }
    end
  end
end