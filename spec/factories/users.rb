FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    role { "user" }
    organization

    trait :admin do
      role { "admin" }
    end

    trait :super_admin do
      role { "super_admin" }
    end

    trait :manager do
      role { "manager" }
    end

    trait :with_documents do
      after(:create) do |user|
        create_list(:document, 5, uploaded_by: user)
      end
    end
  end
end