FactoryBot.define do
  factory :authorization do
    user { association :user }
    user_group { nil }
    authorizable { association :document }
    permission_type { 'read' }
    granted_by { association :user, :admin }
    granted_at { Time.current }
    
    trait :write_permission do
      permission_type { 'write' }
    end
    
    trait :admin_permission do
      permission_type { 'admin' }
    end
    
    trait :validate_permission do
      permission_type { 'validate' }
    end
    
    trait :for_group do
      user { nil }
      user_group { association :user_group }
    end
    
    trait :expired do
      expired_at { 1.day.from_now }
      after(:create) { |auth| auth.update_column(:expired_at, 1.day.ago) }
    end
    
    trait :revoked do
      after(:create) do |auth|
        auth.revoke!(create(:user, :admin), comment: 'Test revocation')
      end
    end
    
    trait :with_expiry do
      expired_at { 1.month.from_now }
    end
  end
end
