FactoryBot.define do
  factory :metadatum do
    document { nil }
    key { "MyString" }
    value { "MyText" }
    metadata_type { "MyString" }
  end

  factory :metadata_template do
    name { Faker::Lorem.words(number: 2).join(" ").titleize }
    description { Faker::Lorem.sentence }
    organization

    trait :with_fields do
      after(:create) do |template|
        create_list(:metadata_field, 3, metadata_template: template)
      end
    end
  end

  factory :metadata_field do
    name { Faker::Lorem.word }
    label { Faker::Lorem.words(number: 2).join(" ").titleize }
    field_type { "string" }
    required { false }
    metadata_template
  end
end
