FactoryBot.define do
  factory :link do
    document { nil }
    linked_document { nil }
    link_type { "MyString" }
  end
end
