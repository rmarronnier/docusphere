# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::DocumentPreviewModalComponent, type: :component do
  let(:organization) { create(:organization, name: "Test Org") }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, parent: space, organization: organization, created_by: user) }
  let(:document) { create(:document, :with_pdf_file, uploaded_by: user, parent: folder) }
  
  subject(:component) { described_class.new(document: document) }

  before do
    # Set up view context for policy helpers
    allow_any_instance_of(DocumentPolicy).to receive(:download?).and_return(true)
    allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(true)
    allow_any_instance_of(DocumentPolicy).to receive(:share?).and_return(true)
  end

  describe "initialization" do
    it "accepts a document parameter" do
      expect(component.send(:document)).to eq(document)
    end

    it "accepts show_actions parameter" do
      component_with_options = described_class.new(document: document, show_actions: false)
      expect(component_with_options.send(:show_actions)).to be(false)
    end

    it "defaults show_actions to true" do
      expect(component.send(:show_actions)).to be(true)
    end
  end

  describe "rendering" do
    it "renders without error" do
      expect { render_inline(component) }.not_to raise_error
    end

    it "includes the document name in the header" do
      render_inline(component)
      expect(page).to have_text(document.name)
    end

    it "includes file extension" do
      render_inline(component)
      expect(page).to have_text(document.file_extension.upcase)
    end

    it "includes file size" do
      render_inline(component)
      expect(page).to have_text(helpers.number_to_human_size(document.file.byte_size))
    end

    it "includes modification time" do
      render_inline(component)
      expect(page).to have_text("Modified")
    end

    it "includes close button" do
      render_inline(component)
      expect(page).to have_css('[aria-label="Close preview"]')
    end

    it "sets up stimulus controller" do
      render_inline(component)
      expect(page).to have_css('[data-controller="document-preview"]')
      expect(page).to have_css("[data-document-preview-id-value='#{document.id}']")
    end
  end

  describe "preview content by file type" do
    context "with PDF document" do
      let(:document) { create(:document, :with_pdf_file, uploaded_by: user, parent: folder) }

      it "renders PDF viewer iframe" do
        render_inline(component)
        expect(page).to have_css('iframe[title*="PDF Viewer"]')
      end
    end

    context "with image document" do
      let(:document) { create(:document, :with_image_file, uploaded_by: user, parent: folder) }

      it "renders image viewer with zoom capability" do
        render_inline(component)
        expect(page).to have_css('[data-controller="image-zoom"]')
        expect(page).to have_css('img.cursor-zoom-in')
      end
    end

    context "with video document" do
      let(:document) do
        doc = create(:document, uploaded_by: user, parent: folder)
        doc.file.attach(
          io: File.open(Rails.root.join("spec/fixtures/sample_video.mp4")),
          filename: "sample_video.mp4",
          content_type: "video/mp4"
        )
        doc
      end

      it "renders video player with controls" do
        render_inline(component)
        expect(page).to have_css('video[controls]')
      end
    end

    context "with text document" do
      let(:document) do
        doc = create(:document, uploaded_by: user, parent: folder)
        doc.file.attach(
          io: StringIO.new("Sample text content"),
          filename: "sample.txt",
          content_type: "text/plain"
        )
        doc
      end

      it "renders text viewer" do
        render_inline(component)
        expect(page).to have_css('.text-viewer pre')
      end
    end

    context "with unsupported document type" do
      let(:document) do
        doc = create(:document, uploaded_by: user, parent: folder)
        doc.file.attach(
          io: StringIO.new("Binary content"),
          filename: "sample.bin",
          content_type: "application/octet-stream"
        )
        doc
      end

      it "renders fallback download prompt" do
        render_inline(component)
        expect(page).to have_text("Preview not available")
        expect(page).to have_text("This file type cannot be previewed in the browser")
      end
    end
  end

  describe "modal actions" do
    context "with permissions" do
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:share?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:download?).and_return(true)
      end

      it "shows download button" do
        render_inline(component)
        expect(page).to have_link("Download", href: ged_document_download_path(document))
      end

      it "shows share button" do
        render_inline(component)
        expect(page).to have_button("Share")
      end

      it "shows edit button" do
        render_inline(component)
        expect(page).to have_link("Edit", href: edit_ged_document_path(document))
      end

      context "with PDF document" do
        let(:document) { create(:document, :with_pdf_file, uploaded_by: user, parent: folder) }

        it "shows open in new tab button" do
          render_inline(component)
          expect(page).to have_link("Open in New Tab")
        end
      end
    end

    context "without permissions" do
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(false)
        allow_any_instance_of(DocumentPolicy).to receive(:share?).and_return(false)
      end

      it "does not show edit button" do
        render_inline(component)
        expect(page).not_to have_link("Edit")
      end

      it "does not show share button" do
        render_inline(component)
        expect(page).not_to have_button("Share")
      end
    end

    context "with show_actions disabled" do
      subject(:component) { described_class.new(document: document, show_actions: false) }

      it "does not show any action buttons" do
        render_inline(component)
        expect(page).not_to have_link("Download")
        expect(page).not_to have_button("Share")
        expect(page).not_to have_link("Edit")
      end
    end
  end

  describe "loading and error states" do
    it "includes loading state element" do
      render_inline(component)
      expect(page).to have_css('[data-document-preview-target="loading"]', visible: :hidden)
      expect(page).to have_text("Loading preview...")
    end

    it "includes error state element" do
      render_inline(component)
      expect(page).to have_css('[data-document-preview-target="error"]', visible: :hidden)
      expect(page).to have_text("Preview Error")
      expect(page).to have_text("Unable to load document preview")
    end
  end

  describe "image zoom modal" do
    let(:document) { create(:document, :with_image_file, uploaded_by: user, parent: folder) }

    it "includes image zoom modal structure" do
      render_inline(component)
      expect(page).to have_css('.image-zoom-modal[data-image-zoom-target="modal"]', visible: :hidden)
      expect(page).to have_css('[data-image-zoom-target="zoomedImage"]')
    end

    it "includes zoom close button" do
      render_inline(component)
      within '.image-zoom-modal' do
        expect(page).to have_css('button[data-action="click->image-zoom#close"]')
      end
    end
  end

  describe "accessibility" do
    it "has proper ARIA labels" do
      render_inline(component)
      expect(page).to have_css('[aria-label="Close preview"]')
    end

    it "has proper heading structure" do
      render_inline(component)
      expect(page).to have_css('h3', text: document.name)
    end

    it "includes alt text for images" do
      document = create(:document, :with_image_file, uploaded_by: user, parent: folder)
      component = described_class.new(document: document)
      render_inline(component)
      expect(page).to have_css("img[alt='#{document.name}']")
    end
  end

  describe "stimulus interactions" do
    it "sets up backdrop click to close" do
      render_inline(component)
      expect(page).to have_css('[data-action="click->document-preview#closeOnBackdrop"]')
    end

    it "prevents propagation on content click" do
      render_inline(component)
      expect(page).to have_css('[data-action="click->document-preview#stopPropagation"]')
    end

    it "sets up close button action" do
      render_inline(component)
      expect(page).to have_css('[data-action="click->document-preview#close"]')
    end

    it "sets up share button action" do
      render_inline(component)
      expect(page).to have_css('[data-action="click->document-preview#share"]')
    end
  end

  describe "responsive design" do
    it "uses responsive width classes" do
      render_inline(component)
      expect(page).to have_css('.w-full.max-w-7xl')
    end

    it "uses responsive padding" do
      render_inline(component)
      expect(page).to have_css('.p-4')
    end
  end

  private

  def helpers
    @helpers ||= ApplicationController.new.view_context
  end
end