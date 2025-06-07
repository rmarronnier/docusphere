FactoryBot.define do
  factory :tag do
    name { Faker::Lorem.unique.word.downcase }

    trait :urgent do
      name { "urgent" }
    end

    trait :important do
      name { "important" }
    end

    trait :confidential do
      name { "confidentiel" }
    end

    trait :with_documents do
      after(:create) do |tag|
        create_list(:document, 5, tags: [tag])
      end
    end
  end
end