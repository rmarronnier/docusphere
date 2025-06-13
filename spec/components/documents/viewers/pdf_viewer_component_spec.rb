# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Documents::Viewers::PdfViewerComponent, type: :component do
  let(:document) { create(:document, :with_pdf_file) }
  let(:component) { described_class.new(document: document) }
  
  before do
    # Mock the file attachment first
    mock_file = double("file")
    allow(mock_file).to receive(:attached?).and_return(true)
    allow(document).to receive(:file).and_return(mock_file)
    
    # Mock helpers with routes
    mock_helpers = double("helpers")
    allow(mock_helpers).to receive(:ged_download_document_path).and_return("/ged/documents/#{document.id}/download")
    allow(mock_helpers).to receive(:rails_blob_url).with(mock_file, disposition: 'inline').and_return("http://example.com/rails/active_storage/blobs/#{document.id}")
    allow_any_instance_of(described_class).to receive(:helpers).and_return(mock_helpers)
  end
  
  describe '#initialize' do
    it 'accepts a document' do
      expect(component).to be_a(described_class)
    end
    
    it 'accepts show_actions parameter' do
      component = described_class.new(document: document, show_actions: false)
      expect(component).to be_a(described_class)
    end
  end
  
  describe 'rendering' do
    it 'renders PDF viewer container' do
      render_inline(component)
      
      expect(page).to have_css('.pdf-viewer-container')
      expect(page).to have_css('[data-controller="pdf-viewer"]')
    end
    
    it 'renders PDF toolbar' do
      render_inline(component)
      
      expect(page).to have_css('.pdf-toolbar')
    end
    
    describe 'navigation controls' do
      it 'renders page navigation buttons' do
        render_inline(component)
        
        expect(page).to have_css('button[data-action="click->pdf-viewer#previousPage"]')
        expect(page).to have_css('button[data-action="click->pdf-viewer#nextPage"]')
      end
      
      it 'renders page input field' do
        render_inline(component)
        
        expect(page).to have_css('input[type="number"][data-pdf-viewer-target="pageInput"]')
        expect(page).to have_css('input[data-action="change->pdf-viewer#goToPage"]')
      end
      
      it 'renders total pages display' do
        render_inline(component)
        
        expect(page).to have_css('[data-pdf-viewer-target="totalPages"]', text: '1')
      end
    end
    
    describe 'zoom controls' do
      it 'renders zoom buttons' do
        render_inline(component)
        
        expect(page).to have_css('button[data-action="click->pdf-viewer#zoomOut"]')
        expect(page).to have_css('button[data-action="click->pdf-viewer#zoomIn"]')
      end
      
      it 'renders zoom select dropdown' do
        render_inline(component)
        
        expect(page).to have_css('select[data-pdf-viewer-target="zoomSelect"]')
        expect(page).to have_css('option[value="auto"]')
        expect(page).to have_css('option[value="1"]', text: '100%')
        expect(page).to have_css('option[value="fit-width"]')
      end
    end
    
    describe 'view controls' do
      it 'renders fullscreen button' do
        render_inline(component)
        
        expect(page).to have_css('button[data-action="click->pdf-viewer#fullscreen"]')
      end
      
      it 'renders print button' do
        render_inline(component)
        
        expect(page).to have_css('button[data-action="click->pdf-viewer#print"]')
      end
      
      context 'with show_actions true' do
        it 'renders download button' do
          render_inline(component)
          
          expect(page).to have_css('a.btn-secondary', text: 'Télécharger')
        end
      end
      
      context 'with show_actions false' do
        let(:component) { described_class.new(document: document, show_actions: false) }
        
        it 'does not render download button' do
          render_inline(component)
          
          expect(page).not_to have_text('Télécharger')
        end
      end
    end
    
    describe 'PDF iframe' do
      it 'renders iframe with correct attributes' do
        render_inline(component)
        
        expect(page).to have_css('iframe[data-pdf-viewer-target="frame"]')
        expect(page).to have_css('iframe.w-full.h-full.border-0')
        expect(page).to have_css('iframe[loading="lazy"]')
      end
      
      context 'with attached file' do
        it 'sets iframe src to blob URL' do
          render_inline(component)
          
          iframe = page.find('iframe')
          expect(iframe['src']).to include('rails/active_storage/blobs')
        end
      end
      
      context 'without attached file' do
        let(:document) { create(:document) }
        
        it 'sets iframe src to #' do
          # Re-mock for this specific test
          mock_helpers = double("helpers")
          allow(mock_helpers).to receive(:ged_download_document_path).and_return("/ged/documents/#{document.id}/download")
          # No rails_blob_url call because no file attached
          allow_any_instance_of(described_class).to receive(:helpers).and_return(mock_helpers)
          
          # Mock the file attachment as false
          allow(document).to receive_message_chain(:file, :attached?).and_return(false)
          
          render_inline(component)
          
          iframe = page.find('iframe')
          expect(iframe['src']).to eq('#')
        end
      end
    end
  end
  
  describe 'icons' do
    it 'uses IconComponent for all icons' do
      render_inline(component)
      
      # Should have multiple SVG elements from IconComponent
      expect(page).to have_css('svg', minimum: 5)
    end
  end
end