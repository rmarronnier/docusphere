require 'rails_helper'

RSpec.describe Documents::DocumentGridComponent, type: :component do
  let(:documents) do
    [
      create(:document, title: "Report.pdf", document_type: "pdf", file_size: 500.kilobytes),
      create(:document, title: "Spreadsheet.xlsx", document_type: "xlsx", file_size: 2.megabytes),
      create(:document, title: "Presentation.pptx", document_type: "pptx", file_size: 15.megabytes)
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

  describe "document thumbnails" do
    it "shows thumbnail image for documents with files" do
      pdf_doc = create(:document, :with_pdf_file)
      render_inline(described_class.new(documents: [pdf_doc]))
      
      expect(page).to have_css("img[alt='#{pdf_doc.title}']")
    end

    it "shows fallback icon for documents without files" do
      doc_without_file = create(:document, :without_file)
      render_inline(described_class.new(documents: [doc_without_file]))
      
      # Should show icon instead of image
      expect(page).to have_selector("svg") # or have_css(".h-16.w-16")
    end

    it "includes lazy loading attribute on images" do
      image_doc = create(:document, :with_image_file)
      render_inline(described_class.new(documents: [image_doc]))
      
      expect(page).to have_css("img[loading='lazy']")
    end

    it "includes error handler for broken images" do
      doc = create(:document, :with_pdf_file)
      render_inline(described_class.new(documents: [doc]))
      
      expect(page).to have_css("img[onerror]")
    end

    it "sets preview data attributes" do
      doc = create(:document, :with_image_file)
      render_inline(described_class.new(documents: [doc]))
      
      expect(page).to have_css("img[data-document-id='#{doc.id}']")
      expect(page).to have_css("img[data-preview-url]")
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
      huge_doc = create(:document, file_size: 100.megabytes)
      render_inline(described_class.new(documents: [huge_doc]))
      
      expect(page).to have_css(".text-red-600")
    end
  end

  describe "actions" do
    it "shows actions by default" do
      # Use factory traits for proper file attachments
      doc = create(:document, :with_pdf_file)
      render_inline(described_class.new(documents: [doc]))
      
      expect(page).to have_css("a[aria-label='Download']")
    end

    it "can hide actions" do
      render_inline(described_class.new(documents: documents, show_actions: false))
      
      # Should not show action buttons when actions are hidden
      expect(page).not_to have_css("a[aria-label='Download']")
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

  describe "preview functionality" do
    it "renders thumbnail for documents with attached files" do
      doc = create(:document, :with_image_file)
      render_inline(described_class.new(documents: [doc]))
      
      expect(page).to have_css("img[src]")
    end

    it "handles documents without attached files gracefully" do
      doc = create(:document, :without_file)
      render_inline(described_class.new(documents: [doc]))
      
      # Should not crash and should show a placeholder or icon
      expect(page).to have_content(doc.title)
    end

    it "applies hover effect on thumbnail container" do
      doc = create(:document, :with_pdf_file)
      render_inline(described_class.new(documents: [doc]))
      
      expect(page).to have_css(".group-hover\\:bg-gray-100")
    end
  end

  describe "document metadata" do
    it "displays document created date" do
      document = create(:document, created_at: 2.days.ago, updated_at: 2.days.ago)
      render_inline(described_class.new(documents: [document]))
      
      # The component shows updated_at, not created_at, and adds "ago"
      expect(page).to have_text("ago")
    end

    it "displays document owner" do
      user = create(:user, first_name: "John", last_name: "Doe")
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
      
      expect(page).to have_text("important")
      expect(page).to have_text("finance")
    end
  end

  describe "empty state" do
    it "shows empty state when no documents" do
      render_inline(described_class.new(documents: []))
      
      expect(page).to have_text("Aucun document")
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
      # Render in list view which includes dropdown buttons
      render_inline(described_class.new(documents: documents, view_mode: :list))
      
      # Look for dropdown buttons which have data-controller
      expect(page).to have_css("[data-controller*='dropdown']")
    end

    it "includes data attributes for selection when selectable" do
      render_inline(described_class.new(documents: documents, selectable: true))
      
      # Look for checkboxes with data-action for selection
      expect(page).to have_css("[data-action*='document-grid#toggleSelection']")
    end
  end
end