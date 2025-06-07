FactoryBot.define do
  factory :document_share do
    document { nil }
    user { nil }
    permission { "MyString" }
    expires_at { "2025-06-07 19:01:15" }
    shared_by { nil }
  end
end
