FactoryBot.define do
  factory :authorization do
    user { association :user }
    user_group { nil }
    authorizable { association :document }
    permission_level { 'read' }
    granted_by { association :user, :admin }
    granted_at { Time.current }
    
    trait :write_permission do
      permission_level { 'write' }
    end
    
    trait :admin_permission do
      permission_level { 'admin' }
    end
    
    trait :validate_permission do
      permission_level { 'validate' }
    end
    
    trait :for_group do
      user { nil }
      user_group { association :user_group }
    end
    
    trait :expired do
      expires_at { 1.day.from_now }
      after(:create) { |auth| auth.update_column(:expires_at, 1.day.ago) }
    end
    
    trait :revoked do
      after(:create) do |auth|
        auth.revoke!(create(:user, :admin), comment: 'Test revocation')
      end
    end
    
    trait :with_expiry do
      expires_at { 1.month.from_now }
    end
  end
end
