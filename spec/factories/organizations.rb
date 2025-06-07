FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
    slug { name.parameterize }
    description { Faker::Company.catch_phrase }

    trait :with_spaces do
      after(:create) do |organization|
        create_list(:space, 3, organization: organization)
      end
    end
  end
end