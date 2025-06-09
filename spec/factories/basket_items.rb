FactoryBot.define do
  factory :basket_item do
    basket
    association :item, factory: :document
    position { 1 }
  end
end