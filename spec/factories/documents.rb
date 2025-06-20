FactoryBot.define do
  factory :document do
    title { Faker::Lorem.words(number: 3).join(' ').capitalize }
    description { Faker::Lorem.paragraph }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    status { "draft" }
    association :uploaded_by, factory: :user
    space
    
    transient do
      file_size { nil }
      attach_file { true }
    end

    after(:build) do |document, evaluator|
      # Only attach file if requested (default true)
      if evaluator.attach_file
        # Create file content with the specified size if file_size is provided
        file_content = if evaluator.try(:file_size)
          "A" * evaluator.file_size
        else
          "Test document content"
        end
        
        document.file.attach(
          io: StringIO.new(file_content),
          filename: "test_document.pdf",
          content_type: "application/pdf"
        )
      end
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
    
    trait :with_image_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Fake image content"),
          filename: "test_image.jpg",
          content_type: "image/jpeg"
        )
      end
    end
    
    trait :with_pdf_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("%PDF-1.4 test content"),
          filename: "test.pdf",
          content_type: "application/pdf"
        )
      end
    end
    
    trait :without_file do
      attach_file { false }
      skip_file_validation { true }
    end
    
    trait :with_video_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Fake video content"),
          filename: "test_video.mp4",
          content_type: "video/mp4"
        )
      end
    end
    
    trait :with_excel_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Excel file content"),
          filename: "test.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
      end
    end
    
    trait :with_xlsx_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Excel file content"),
          filename: "test.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
      end
    end
    
    trait :with_docx_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Word document content"),
          filename: "test.docx",
          content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        )
      end
    end
    
    trait :with_txt_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Plain text content\nLine 2\nLine 3"),
          filename: "test.txt",
          content_type: "text/plain"
        )
      end
    end
    
    trait :with_text_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("def hello\n  puts 'Hello, World!'\nend"),
          filename: "test.rb",
          content_type: "text/plain"
        )
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