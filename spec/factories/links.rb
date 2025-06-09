FactoryBot.define do
  factory :link do
    association :source, factory: :document
    association :target, factory: :document
    link_type { "reference" }
  end
end
