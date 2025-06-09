FactoryBot.define do
  factory :user_group_membership do
    user
    user_group
    role { "member" }
    
    trait :admin do
      role { "admin" }
    end
  end
end
