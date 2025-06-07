FactoryBot.define do
  factory :document_metadatum do
    document { nil }
    key { "MyString" }
    value { "MyText" }
    metadata_type { "MyString" }
  end
end
