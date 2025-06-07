FactoryBot.define do
  factory :authorization do
    association :user
    association :user_group
    authorizable { association :space }
    permission_type { "read" }
  end
end
