FactoryBot.define do
  factory :metadatum do
    association :metadatable, factory: :document
    key { Faker::Lorem.word }
    value { Faker::Lorem.sentence }
    
    trait :with_field do
      metadata_field
      key { nil }
    end
    
    trait :boolean_type do
      value { "true" }
      with_field
      metadata_field { association :metadata_field, field_type: 'boolean' }
    end
    
    trait :date_type do
      value { Date.current.to_s }
      with_field
      metadata_field { association :metadata_field, field_type: 'date' }
    end
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
