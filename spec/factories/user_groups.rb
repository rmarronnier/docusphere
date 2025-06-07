FactoryBot.define do
  factory :user_group do
    sequence(:name) { |n| "User Group #{n}" }
    description { "A user group for access control" }
    association :organization
    group_type { nil }
    is_active { true }
    
    trait :department do
      group_type { "department" }
    end
    
    trait :project_team do
      group_type { "project_team" }
    end
    
    trait :inactive do
      is_active { false }
    end
    
    trait :with_users do
      after(:create) do |group|
        create_list(:user_group_membership, 3, user_group: group)
      end
    end
  end
end
