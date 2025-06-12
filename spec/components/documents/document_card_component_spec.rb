require 'rails_helper'

RSpec.describe Documents::DocumentCardComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  let(:folder) { create(:folder, space: space) }
  let(:document) { create(:document, 
    title: "Test Document",
    description: "A test description",
    parent: folder,
    uploaded_by: user,
    processing_status: 'completed',
    status: 'published'
  )}
  
  before do
    mock_component_helpers(described_class, user: user, additional_helpers: {
      ged_document_path: ->(doc) { "/ged/documents/#{doc.id}" },
      ged_document_download_path: ->(doc) { "/ged/documents/#{doc.id}/download" },
      edit_ged_document_path: ->(doc) { "/ged/documents/#{doc.id}/edit" },
      new_ged_document_document_share_path: ->(doc) { "/ged/documents/#{doc.id}/shares/new" },
      image_tag: ->(src, options = {}) { "<img src='#{src}' #{options.map{|k,v| "#{k}='#{v}'"}.join(' ')}/>".html_safe },
      rails_blob_path: ->(attachment) { "/rails/active_storage/blobs/#{attachment.key}" },
      rails_representation_path: ->(variant) { "/rails/active_storage/representations/#{variant.key}" },
      asset_path: ->(path) { "/assets/#{path}" },
      heroicon: ->(name, options = {}) { "<svg class='#{options[:options]&.dig(:class)}'><use href='##{name}'></use></svg>".html_safe },
      t: ->(key, options = {}) { I18n.t(key, options) },
      policy: ->(record) {
        double(
          update?: true,
          destroy?: true,
          share?: true
        )
      }
    })
  end

  describe "initialization" do
    it "accepts default parameters" do
      component = described_class.new(document: document)
      expect(component.send(:document)).to eq(document)
      expect(component.send(:show_preview)).to be true
      expect(component.send(:show_actions)).to be true
      expect(component.send(:clickable)).to be true
    end

    it "accepts custom parameters" do
      component = described_class.new(
        document: document,
        show_preview: false,
        show_actions: false,
        clickable: false
      )
      expect(component.send(:show_preview)).to be false
      expect(component.send(:show_actions)).to be false
      expect(component.send(:clickable)).to be false
    end
  end
  
  describe "rendering" do
    it "renders document title" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_content("Test Document")
      expect(rendered).to have_link("Test Document")
    end
    
    it "renders document metadata" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_content("A test description")
      expect(rendered).to have_content("21 B") # File size
    end
    
    it "shows document status" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_content(I18n.t("documents.status.published"))
    end

    it "includes document preview controller" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_css('[data-controller="document-preview"]')
    end
  end

  describe "thumbnail display" do
    context "with image document" do
      let(:document) { create(:document, :with_image_file, parent: folder, uploaded_by: user) }

      it "displays image thumbnail" do
        rendered = render_inline(described_class.new(document: document))
        
        expect(rendered).to have_css('img[loading="lazy"]')
      end
    end

    context "with PDF document" do
      let(:document) { create(:document, :with_pdf_file, parent: folder, uploaded_by: user) }

      it "displays icon fallback for PDF" do
        rendered = render_inline(described_class.new(document: document))
        
        expect(rendered).to have_css('.bg-gradient-to-br')
      end

      it "shows file extension badge" do
        rendered = render_inline(described_class.new(document: document))
        
        expect(rendered).to have_content('PDF')
      end
    end

    context "without preview enabled" do
      it "does not show thumbnail area" do
        rendered = render_inline(described_class.new(document: document, show_preview: false))
        
        expect(rendered).not_to have_css('.h-32')
      end
    end
  end

  describe "quick actions" do
    context "with PDF document" do
      let(:document) { create(:document, :with_pdf_file, parent: folder, uploaded_by: user) }

      it "shows preview button" do
        rendered = render_inline(described_class.new(document: document))
        
        expect(rendered).to have_css('[data-action="click->document-preview#open"]')
        expect(rendered).to have_content('Preview')
      end
    end

    it "shows download button for documents with files" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_content('Download')
      expect(rendered).to have_link(href: "/ged/documents/#{document.id}/download")
    end

    context "without actions enabled" do
      it "hides all actions" do
        rendered = render_inline(described_class.new(document: document, show_actions: false))
        
        expect(rendered).not_to have_css('[data-controller="dropdown"]')
        expect(rendered).not_to have_content('Download')
        expect(rendered).not_to have_content('Preview')
      end
    end
  end
  
  describe "action menu" do
    it "renders dropdown menu" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_css('[data-controller="dropdown"]')
      expect(rendered).to have_css('[data-action="click->dropdown#toggle"]')
    end
    
    it "includes contextual actions" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_link("View")
      expect(rendered).to have_link("Edit")
      expect(rendered).to have_link("Download")
      expect(rendered).to have_link("Share")
      expect(rendered).to have_link("Delete")
    end
    
    it "hides actions based on permissions" do
      mock_component_helpers(described_class, user: user, additional_helpers: {
        ged_document_path: ->(doc) { "/ged/documents/#{doc.id}" },
        ged_document_download_path: ->(doc) { "/ged/documents/#{doc.id}/download" },
        edit_ged_document_path: ->(doc) { "/ged/documents/#{doc.id}/edit" },
        new_ged_document_document_share_path: ->(doc) { "/ged/documents/#{doc.id}/shares/new" },
        image_tag: ->(src, options = {}) { "<img src='#{src}' #{options.map{|k,v| "#{k}='#{v}'"}.join(' ')}/>".html_safe },
        rails_blob_path: ->(attachment) { "/rails/active_storage/blobs/#{attachment.key}" },
        rails_representation_path: ->(variant) { "/rails/active_storage/representations/#{variant.key}" },
        asset_path: ->(path) { "/assets/#{path}" },
        heroicon: ->(name, options = {}) { "<svg class='#{options[:options]&.dig(:class)}'><use href='##{name}'></use></svg>".html_safe },
        t: ->(key, options = {}) { I18n.t(key, options) },
        policy: ->(record) {
          double(
            update?: false,
            destroy?: false,
            share?: false
          )
        }
      })
      
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).not_to have_link("Delete")
      expect(rendered).not_to have_link("Edit")
      expect(rendered).not_to have_link("Share")
    end
  end
  
  describe "with tags" do
    let(:tag1) { create(:tag, name: "Important", organization: user.organization) }
    let(:tag2) { create(:tag, name: "Contrat", organization: user.organization) }
    
    before do
      document.tags << [tag1, tag2]
    end
    
    it "displays document tags" do
      rendered = render_inline(described_class.new(document: document))
      
      # Tags are normalized to lowercase by the Tag model
      expect(rendered).to have_content("important")
      expect(rendered).to have_content("contrat")
    end

    it "shows tag count when more than 3" do
      3.times { |i| document.tags << create(:tag, name: "Tag#{i}", organization: user.organization) }
      
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_content("+2")
    end
  end

  describe "clickable behavior" do
    context "when clickable is true" do
      it "links to document path" do
        rendered = render_inline(described_class.new(document: document, clickable: true))
        
        expect(rendered).to have_link(href: "/ged/documents/#{document.id}")
      end
    end

    context "when clickable is false" do
      it "does not link to document" do
        rendered = render_inline(described_class.new(document: document, clickable: false))
        
        expect(rendered).to have_link(href: "#")
      end
    end
  end

  describe "preview modal integration" do
    context "with previewable document" do
      let(:document) { create(:document, :with_pdf_file, parent: folder, uploaded_by: user) }

      it "includes preview modal component" do
        rendered = render_inline(described_class.new(document: document))
        
        expect(rendered).to have_css('.document-preview-modal')
      end
    end

    context "with non-previewable document" do
      it "does not include preview modal" do
        allow(document).to receive(:pdf?).and_return(false)
        allow(document).to receive(:image?).and_return(false)
        
        rendered = render_inline(described_class.new(document: document))
        
        expect(rendered).not_to have_css('.document-preview-modal')
      end
    end
  end

  describe "responsive design" do
    it "uses responsive classes" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_css('.hover\\:shadow-lg')
      expect(rendered).to have_css('.transition-all')
      expect(rendered).to have_css('.group')
    end
  end
end