FactoryBot.define do
  factory :share do
    document { nil }
    user { nil }
    permission { "MyString" }
    expires_at { "2025-06-07 19:01:59" }
    shared_by { nil }
  end
end
