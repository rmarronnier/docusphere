FactoryBot.define do
  factory :share do
    association :shareable, factory: :document
    association :shared_with, factory: :user
    association :shared_by, factory: :user
    access_level { "read" }
    expires_at { 1.week.from_now }
  end
end
