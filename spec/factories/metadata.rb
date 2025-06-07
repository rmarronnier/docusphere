FactoryBot.define do
  factory :metadatum do
    document { nil }
    key { "MyString" }
    value { "MyText" }
    metadata_type { "MyString" }
  end
end
