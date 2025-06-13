FactoryBot.define do
  factory :client do
    sequence(:name) { |n| "Client #{n}" }
    status { 'active' }
    sequence(:email) { |n| "client#{n}@example.com" }
    phone { '+33 1 23 45 67 89' }
    address { '123 Rue de la Paix, Paris' }
    
    # Support pour les tests qui passent organization directement
    transient do
      organization { nil }
    end
    
    after(:create) do |client, evaluator|
      if evaluator.organization
        create(:client_relationship, client: client, organization: evaluator.organization, relationship_type: 'managed')
      end
    end
    
    trait :prospect do
      status { 'prospect' }
    end
    
    trait :active do
      status { 'active' }
    end
    
    trait :inactive do
      status { 'inactive' }
    end
  end
end