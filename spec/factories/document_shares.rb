FactoryBot.define do
  factory :document_share do
    document
    association :shared_by, factory: :user
    association :shared_with, factory: :user
    access_level { 'read' }
    is_active { true }
    expires_at { nil }
    
    trait :with_email do
      email { 'guest@example.com' }
      shared_with { nil }
    end
    
    trait :write_access do
      access_level { 'write' }
    end
    
    trait :admin_access do
      access_level { 'admin' }
    end
    
    trait :expired do
      expires_at { 1.day.ago }
    end
    
    trait :inactive do
      is_active { false }
    end
  end
end