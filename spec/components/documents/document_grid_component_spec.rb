require 'rails_helper'

RSpec.describe Documents::DocumentGridComponent, type: :component do
  let(:documents) do
    [
      create(:document, name: "Report.pdf", document_type: "pdf", file_size: 500.kilobytes),
      create(:document, name: "Spreadsheet.xlsx", document_type: "xlsx", file_size: 2.megabytes),
      create(:document, name: "Presentation.pptx", document_type: "pptx", file_size: 15.megabytes)
    ]
  end

  describe "basic rendering" do
    it "renders documents in grid view by default" do
      render_inline(described_class.new(documents: documents))
      
      expect(page).to have_css(".grid")
      expect(page).to have_css(".grid-cols-1")
      expect(page).to have_css(".sm\\:grid-cols-2")
      expect(page).to have_css(".lg\\:grid-cols-3")
      expect(page).to have_css(".xl\\:grid-cols-4")
    end

    it "renders all documents" do
      render_inline(described_class.new(documents: documents))
      
      expect(page).to have_text("Report.pdf")
      expect(page).to have_text("Spreadsheet.xlsx")
      expect(page).to have_text("Presentation.pptx")
    end
  end

  describe "view modes" do
    it "renders in grid view" do
      render_inline(described_class.new(documents: documents, view_mode: :grid))
      
      expect(page).to have_css(".grid")
      expect(page).to have_css(".gap-4")
    end

    it "renders in list view" do
      render_inline(described_class.new(documents: documents, view_mode: :list))
      
      expect(page).to have_css(".space-y-3")
      expect(page).not_to have_css(".grid")
    end

    it "renders in compact view" do
      render_inline(described_class.new(documents: documents, view_mode: :compact))
      
      expect(page).to have_css(".divide-y")
      expect(page).to have_css(".divide-gray-200")
      expect(page).not_to have_css(".grid")
    end
  end

  describe "document icons" do
    it "shows appropriate icon for PDF files" do
      pdf_doc = create(:document, document_type: "pdf")
      render_inline(described_class.new(documents: [pdf_doc]))
      
      expect(page).to have_css(".text-red-500")
    end

    it "shows appropriate icon for Word documents" do
      word_doc = create(:document, document_type: "docx")
      render_inline(described_class.new(documents: [word_doc]))
      
      expect(page).to have_css(".text-blue-500")
    end

    it "shows appropriate icon for Excel files" do
      excel_doc = create(:document, document_type: "xlsx")
      render_inline(described_class.new(documents: [excel_doc]))
      
      expect(page).to have_css(".text-green-500")
    end

    it "shows appropriate icon for PowerPoint files" do
      ppt_doc = create(:document, document_type: "pptx")
      render_inline(described_class.new(documents: [ppt_doc]))
      
      expect(page).to have_css(".text-orange-500")
    end

    it "shows appropriate icon for image files" do
      image_doc = create(:document, document_type: "jpg")
      render_inline(described_class.new(documents: [image_doc]))
      
      expect(page).to have_css(".text-purple-500")
    end

    it "shows default icon for unknown file types" do
      unknown_doc = create(:document, document_type: "xyz")
      render_inline(described_class.new(documents: [unknown_doc]))
      
      expect(page).to have_css(".text-gray-400")
    end
  end

  describe "file size indicators" do
    it "shows green for small files" do
      small_doc = create(:document, file_size: 500.kilobytes)
      render_inline(described_class.new(documents: [small_doc]))
      
      expect(page).to have_css(".text-green-600")
    end

    it "shows yellow for medium files" do
      medium_doc = create(:document, file_size: 5.megabytes)
      render_inline(described_class.new(documents: [medium_doc]))
      
      expect(page).to have_css(".text-yellow-600")
    end

    it "shows orange for large files" do
      large_doc = create(:document, file_size: 50.megabytes)
      render_inline(described_class.new(documents: [large_doc]))
      
      expect(page).to have_css(".text-orange-600")
    end

    it "shows red for very large files" do
      huge_doc = create(:document, file_size: 150.megabytes)
      render_inline(described_class.new(documents: [huge_doc]))
      
      expect(page).to have_css(".text-red-600")
    end
  end

  describe "actions" do
    it "shows actions by default" do
      render_inline(described_class.new(documents: documents))
      
      expect(page).to have_css("[data-action]")
    end

    it "can hide actions" do
      render_inline(described_class.new(documents: documents, show_actions: false))
      
      expect(page).not_to have_css("[data-action]")
    end
  end

  describe "selection" do
    it "shows checkboxes when selectable" do
      render_inline(described_class.new(documents: documents, selectable: true))
      
      expect(page).to have_css("input[type='checkbox']", count: documents.size)
    end

    it "does not show checkboxes by default" do
      render_inline(described_class.new(documents: documents, selectable: false))
      
      expect(page).not_to have_css("input[type='checkbox']")
    end

    it "includes data attributes for selection handling" do
      render_inline(described_class.new(documents: documents, selectable: true))
      
      expect(page).to have_css("[data-document-id]")
    end
  end

  describe "preview availability" do
    it "indicates preview available for images" do
      image_doc = create(:document, document_type: "jpg")
      allow(image_doc).to receive_message_chain(:file, :attached?).and_return(true)
      
      render_inline(described_class.new(documents: [image_doc]))
      
      expect(page).to have_css("[data-preview-available='true']")
    end

    it "indicates preview available for PDFs" do
      pdf_doc = create(:document, document_type: "pdf")
      allow(pdf_doc).to receive_message_chain(:file, :attached?).and_return(true)
      
      render_inline(described_class.new(documents: [pdf_doc]))
      
      expect(page).to have_css("[data-preview-available='true']")
    end

    it "indicates no preview for other file types" do
      excel_doc = create(:document, document_type: "xlsx")
      allow(excel_doc).to receive_message_chain(:file, :attached?).and_return(true)
      
      render_inline(described_class.new(documents: [excel_doc]))
      
      expect(page).to have_css("[data-preview-available='false']")
    end
  end

  describe "document metadata" do
    it "displays document created date" do
      document = create(:document, created_at: 2.days.ago)
      render_inline(described_class.new(documents: [document]))
      
      expect(page).to have_text("2 days ago")
    end

    it "displays document owner" do
      user = create(:user, name: "John Doe")
      document = create(:document, uploaded_by: user)
      render_inline(described_class.new(documents: [document]))
      
      expect(page).to have_text("John Doe")
    end

    it "displays document tags" do
      tag1 = create(:tag, name: "Important")
      tag2 = create(:tag, name: "Finance")
      document = create(:document)
      document.tags << [tag1, tag2]
      
      render_inline(described_class.new(documents: [document]))
      
      expect(page).to have_text("Important")
      expect(page).to have_text("Finance")
    end
  end

  describe "empty state" do
    it "shows empty state when no documents" do
      render_inline(described_class.new(documents: []))
      
      expect(page).to have_text("No documents found")
    end
  end

  describe "custom classes" do
    it "accepts custom wrapper classes" do
      render_inline(described_class.new(
        documents: documents,
        class: "custom-document-grid"
      ))
      
      expect(page).to have_css(".custom-document-grid")
    end
  end

  describe "responsive behavior" do
    it "applies responsive grid columns" do
      render_inline(described_class.new(documents: documents, view_mode: :grid))
      
      expect(page).to have_css(".grid-cols-1")
      expect(page).to have_css(".sm\\:grid-cols-2")
      expect(page).to have_css(".lg\\:grid-cols-3")
      expect(page).to have_css(".xl\\:grid-cols-4")
    end
  end

  describe "accessibility" do
    it "includes proper ARIA labels for actions" do
      render_inline(described_class.new(documents: documents))
      
      expect(page).to have_css("[aria-label]")
    end

    it "includes role attributes for interactive elements" do
      render_inline(described_class.new(documents: documents, selectable: true))
      
      expect(page).to have_css("[role='checkbox']")
    end
  end

  describe "stimulus integration" do
    it "includes data attributes for document actions" do
      render_inline(described_class.new(documents: documents))
      
      expect(page).to have_css("[data-controller='document-actions']")
    end

    it "includes data attributes for selection when selectable" do
      render_inline(described_class.new(documents: documents, selectable: true))
      
      expect(page).to have_css("[data-controller='document-selection']")
    end
  end
end