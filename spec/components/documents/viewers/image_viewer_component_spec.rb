# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Documents::Viewers::ImageViewerComponent, type: :component do
  let(:document) { create(:document, :with_image_file) }
  let(:component) { described_class.new(document: document) }
  
  before do
    # Mock the file attachment first
    mock_file = double("file")
    allow(mock_file).to receive(:attached?).and_return(true)
    allow(document).to receive(:file).and_return(mock_file)
    
    # Mock helpers with routes
    mock_helpers = double("helpers")
    allow(mock_helpers).to receive(:ged_download_document_path).and_return("/ged/documents/#{document.id}/download")
    allow(mock_helpers).to receive(:rails_blob_url).with(mock_file).and_return("http://example.com/rails/active_storage/blobs/#{document.id}")
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
    it 'renders image viewer container' do
      render_inline(component)
      
      expect(page).to have_css('.image-viewer-container')
      expect(page).to have_css('[data-controller="image-viewer"]')
    end
    
    it 'renders image toolbar' do
      render_inline(component)
      
      expect(page).to have_css('.image-toolbar')
    end
    
    describe 'collection navigation' do
      context 'when part of a collection' do
        before do
          allow(document).to receive(:part_of_collection?).and_return(true)
          allow(document).to receive(:collection_index).and_return(2)
          allow(document).to receive(:collection_count).and_return(5)
        end
        
        it 'shows navigation controls' do
          render_inline(component)
          
          expect(page).to have_css('button[data-action="click->image-viewer#previous"]')
          expect(page).to have_css('button[data-action="click->image-viewer#next"]')
          expect(page).to have_text('3 / 5') # collection_index + 1
        end
      end
      
      context 'when not part of a collection' do
        before do
          allow(document).to receive(:part_of_collection?).and_return(false)
        end
        
        it 'does not show navigation controls' do
          render_inline(component)
          
          expect(page).not_to have_css('button[data-action="click->image-viewer#previous"]')
          expect(page).not_to have_css('button[data-action="click->image-viewer#next"]')
        end
      end
    end
    
    describe 'zoom controls' do
      it 'renders zoom buttons' do
        render_inline(component)
        
        expect(page).to have_css('button[data-action="click->image-viewer#zoomOut"]')
        expect(page).to have_css('button[data-action="click->image-viewer#zoomIn"]')
      end
      
      it 'renders zoom level display' do
        render_inline(component)
        
        expect(page).to have_css('[data-image-viewer-target="zoomLevel"]', text: '100%')
      end
      
      it 'renders fit and actual size buttons' do
        render_inline(component)
        
        expect(page).to have_css('button[data-action="click->image-viewer#fit"]')
        expect(page).to have_css('button[data-action="click->image-viewer#actualSize"]')
      end
    end
    
    describe 'transform controls' do
      it 'renders rotation button' do
        render_inline(component)
        
        expect(page).to have_css('button[data-action="click->image-viewer#rotate"]')
      end
      
      it 'renders flip buttons' do
        render_inline(component)
        
        expect(page).to have_css('button[data-action="click->image-viewer#flipHorizontal"]')
        expect(page).to have_css('button[data-action="click->image-viewer#flipVertical"]')
      end
    end
    
    describe 'image display' do
      it 'renders image with correct attributes' do
        render_inline(component)
        
        image = page.find('img[data-image-viewer-target="image"]')
        expect(image['alt']).to eq(document.title)
        expect(image['class']).to include('max-w-full', 'max-h-full', 'cursor-move')
        expect(image['draggable']).to eq('false')
      end
      
      it 'sets up image interaction events' do
        render_inline(component)
        
        image = page.find('img[data-image-viewer-target="image"]')
        expect(image['data-action']).to include('wheel->image-viewer#handleWheel')
        expect(image['data-action']).to include('mousedown->image-viewer#startDrag')
        expect(image['data-action']).to include('dblclick->image-viewer#toggleZoom')
      end
    end
    
    describe 'download button' do
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
  end
end