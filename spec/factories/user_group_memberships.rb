FactoryBot.define do
  factory :user_group_membership do
    user { nil }
    user_group { nil }
    role { "MyString" }
    permissions { "MyText" }
  end
end
