# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Documents::Viewers::VideoPlayerComponent, type: :component do
  let(:document) { create(:document, :with_video_file) }
  let(:component) { described_class.new(document: document) }
  
  before do
    # Mock the file attachment first
    mock_file = double("file")
    mock_blob = double("blob", content_type: 'video/mp4')
    allow(mock_file).to receive(:attached?).and_return(true)
    allow(mock_file).to receive(:blob).and_return(mock_blob)
    allow(document).to receive(:file).and_return(mock_file)
    
    # Mock helpers with routes
    mock_helpers = double("helpers")
    allow(mock_helpers).to receive(:ged_download_document_path).and_return("/ged/documents/#{document.id}/download")
    allow(mock_helpers).to receive(:rails_blob_url).with(mock_file).and_return("http://example.com/rails/active_storage/blobs/#{document.id}")
    allow_any_instance_of(described_class).to receive(:helpers).and_return(mock_helpers)
    
    # Mock thumbnail for all tests by default
    mock_thumbnail = double("thumbnail")
    allow(mock_thumbnail).to receive(:attached?).and_return(false)
    allow(document).to receive(:thumbnail).and_return(mock_thumbnail)
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
    it 'renders video player container' do
      render_inline(component)
      
      expect(page).to have_css('.video-player-container')
      expect(page).to have_css('.video-player-container.bg-black')
    end
    
    it 'renders video element' do
      render_inline(component)
      
      expect(page).to have_css('video[controls]')
      expect(page).to have_css('video[data-video-player-target="video"]')
    end
    
    it 'includes nodownload in controls list' do
      render_inline(component)
      
      video = page.find('video')
      expect(video['controlslist']).to eq('nodownload')
    end
    
    describe 'video source' do
      it 'renders source element with correct type' do
        render_inline(component)
        
        source = page.find('source')
        expect(source['src']).to include('rails/active_storage/blobs')
        expect(source['type']).to eq('video/mp4')
      end
      
      it 'includes fallback message' do
        render_inline(component)
        
        expect(page).to have_text('Your browser does not support the video tag.')
      end
    end
    
    describe 'video poster' do
      context 'with thumbnail attached' do
        before do
          # Override the default thumbnail mock for this test
          mock_thumbnail = double("thumbnail")
          allow(mock_thumbnail).to receive(:attached?).and_return(true)
          allow(document).to receive(:thumbnail).and_return(mock_thumbnail)
          
          # Re-mock helpers to handle both file and thumbnail
          mock_file = double("file")
          mock_blob = double("blob", content_type: 'video/mp4')
          allow(mock_file).to receive(:attached?).and_return(true)
          allow(mock_file).to receive(:blob).and_return(mock_blob)
          allow(document).to receive(:file).and_return(mock_file)
          
          mock_helpers = double("helpers")
          allow(mock_helpers).to receive(:ged_download_document_path).and_return("/ged/documents/#{document.id}/download")
          allow(mock_helpers).to receive(:rails_blob_url).with(mock_file).and_return("http://example.com/rails/active_storage/blobs/#{document.id}")
          allow(mock_helpers).to receive(:rails_blob_url).with(mock_thumbnail).and_return("http://example.com/thumbnail/#{document.id}")
          allow_any_instance_of(described_class).to receive(:helpers).and_return(mock_helpers)
        end
        
        it 'sets poster attribute' do
          render_inline(component)
          
          video = page.find('video')
          expect(video['poster']).to be_present
        end
      end
      
      context 'without thumbnail' do
        it 'does not set poster attribute' do
          render_inline(component)
          
          video = page.find('video')
          expect(video['poster']).to be_nil
        end
      end
    end
    
    describe 'controls bar' do
      context 'with show_actions true' do
        it 'renders custom controls bar' do
          render_inline(component)
          
          expect(page).to have_css('.video-controls')
          expect(page).to have_css('.video-controls.bg-gray-900.text-white')
        end
        
        it 'shows document title' do
          render_inline(component)
          
          expect(page).to have_text(document.title)
        end
        
        it 'renders download button' do
          render_inline(component)
          
          expect(page).to have_css('a.btn-secondary', text: 'Télécharger')
        end
      end
      
      context 'with show_actions false' do
        let(:component) { described_class.new(document: document, show_actions: false) }
        
        it 'does not render custom controls bar' do
          render_inline(component)
          
          expect(page).not_to have_css('.video-controls')
          expect(page).not_to have_text('Télécharger')
        end
      end
    end
    
    describe 'responsive design' do
      it 'uses flexbox layout' do
        render_inline(component)
        
        expect(page).to have_css('.h-full.flex.flex-col')
        expect(page).to have_css('.flex-1.flex.items-center.justify-center')
      end
      
      it 'constrains video size' do
        render_inline(component)
        
        expect(page).to have_css('video.max-w-full.max-h-full')
      end
    end
  end
end