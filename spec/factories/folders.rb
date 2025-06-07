FactoryBot.define do
  factory :folder do
    name { Faker::File.dir }
    description { Faker::Lorem.sentence }
    space

    trait :with_parent do
      association :parent, factory: :folder
    end

    trait :with_children do
      after(:create) do |folder|
        create_list(:folder, 3, parent: folder, space: folder.space)
      end
    end

    trait :with_documents do
      after(:create) do |folder|
        create_list(:document, 5, folder: folder, space: folder.space)
      end
    end
  end
end