FactoryBot.define do
  factory :document_version do
    document
    association :created_by, factory: :user
    version_number { 1 }
    comment { Faker::Lorem.sentence }

    after(:build) do |version|
      version.file.attach(
        io: StringIO.new("Version #{version.version_number} content"),
        filename: "version_#{version.version_number}.pdf",
        content_type: "application/pdf"
      )
    end

    trait :with_comment do
      comment { Faker::Lorem.paragraph }
    end
  end
end