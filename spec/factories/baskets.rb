FactoryBot.define do
  factory :basket do
    user
    sequence(:name) { |n| "Panier #{n}" }
    description { "Description du panier" }
    is_shared { false }
    
    trait :shared do
      is_shared { true }
    end
    
    trait :with_documents do
      after(:create) do |basket|
        create_list(:basket_item, 3, basket: basket)
      end
    end
  end
  
end