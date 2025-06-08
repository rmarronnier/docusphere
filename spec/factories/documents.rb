FactoryBot.define do
  factory :document do
    title { Faker::Lorem.words(number: 3).join(' ').capitalize }
    description { Faker::Lorem.paragraph }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    status { "draft" }
    association :uploaded_by, factory: :user
    space

    after(:build) do |document|
      document.file.attach(
        io: StringIO.new("Test document content"),
        filename: "test_document.pdf",
        content_type: "application/pdf"
      )
    end

    trait :published do
      status { "published" }
    end

    trait :locked do
      status { "locked" }
    end

    trait :archived do
      status { "archived" }
    end

    trait :with_folder do
      folder
    end

    trait :with_tags do
      after(:create) do |document|
        document.tags << create_list(:tag, 3, organization: document.space.organization)
      end
    end

    trait :with_versions do
      # Paper Trail is used for versioning
      after(:create) do |document|
        document.update!(title: "#{document.title} - Version 2")
        document.update!(title: "#{document.title} - Version 3")
      end
    end

    factory :pdf_document do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("%PDF-1.4 test content"),
          filename: "test.pdf",
          content_type: "application/pdf"
        )
      end
    end

    factory :word_document do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Word document content"),
          filename: "test.docx",
          content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        )
      end
    end

    factory :image_document do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Image content"),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  end
end