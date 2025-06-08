FactoryBot.define do
  factory :basket do
    user
    sequence(:name) { |n| "Panier #{n}" }
    description { "Description du panier" }
    is_shared { false }
    
    trait :shared do
      is_shared { true }
      share_token { SecureRandom.hex(16) }
      share_expires_at { 7.days.from_now }
    end
    
    trait :with_documents do
      after(:create) do |basket|
        create_list(:basket_item, 3, basket: basket)
      end
    end
  end
  
  factory :basket_item do
    basket
    association :item, factory: :document
    position { 1 }
    notes { "Notes sur le document" }
  end
end