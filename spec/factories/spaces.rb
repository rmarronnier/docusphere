FactoryBot.define do
  factory :space do
    sequence(:name) { |n| "#{Faker::Company.department} #{n}" }
    slug { name.parameterize }
    description { Faker::Lorem.paragraph }
    organization

    trait :with_folders do
      after(:create) do |space|
        create_list(:folder, 3, space: space)
      end
    end

    trait :with_documents do
      after(:create) do |space|
        create_list(:document, 10, space: space)
      end
    end
  end
end