require 'rails_helper'

RSpec.describe Dashboard::RecentDocumentsWidget, type: :component do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  let(:widget_data) do
    {
      id: 1,
      type: 'recent_documents',
      title: 'Documents récents',
      config: {},
      data: { documents: documents }
    }
  end
  
  context 'with documents' do
    let!(:documents) do
      [
        create(:document, 
          title: 'Rapport.pdf',
          uploaded_by: user,
          space: space,
          created_at: 1.hour.ago,
          file_size: 1.megabyte
        ),
        create(:document,
          title: 'Présentation.pptx', 
          uploaded_by: user,
          space: space,
          created_at: 1.day.ago,
          file_size: 5.megabytes
        ),
        create(:document,
          title: 'Budget.xlsx',
          uploaded_by: user,
          space: space,
          created_at: 3.days.ago,
          file_size: 500.kilobytes
        )
      ]
    end
    
    it 'renders document list' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Documents récents')
      expect(page).to have_text('Rapport.pdf')
      expect(page).to have_text('Présentation.pptx')
      expect(page).to have_text('Budget.xlsx')
    end
    
    it 'shows file sizes' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('1 MB')
      expect(page).to have_text('5 MB')
      expect(page).to have_text('500 KB')
    end
    
    it 'shows relative timestamps' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('il y a environ une heure')
      expect(page).to have_text('il y a 1 jour')
      expect(page).to have_text('il y a 3 jours')
    end
    
    it 'renders document icons based on type' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-file-type="pdf"]')
      expect(page).to have_css('[data-file-type="pptx"]')
      expect(page).to have_css('[data-file-type="xlsx"]')
    end
    
    it 'includes links to documents' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      documents.each do |doc|
        expect(page).to have_link(doc.title, href: "/ged/documents/#{doc.id}")
      end
    end
  end
  
  context 'without documents' do
    let(:documents) { [] }
    
    it 'shows empty state' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Aucun document récent')
      expect(page).to have_css('.empty-state')
    end
    
    it 'shows upload button' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_link('Uploader un document', href: '/ged/upload')
    end
  end
  
  context 'with loading state' do
    let(:documents) { [] }
    
    it 'shows loading skeleton' do
      render_inline(described_class.new(
        widget_data: widget_data.merge(loading: true), 
        user: user
      ))
      
      expect(page).to have_css('.loading-skeleton')
    end
  end
  
  context 'with custom limit' do
    let(:documents) { create_list(:document, 10, uploaded_by: user, space: space) }
    
    it 'respects the configured limit' do
      widget_data[:config][:limit] = 5
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('.document-item', count: 5)
    end
  end
  
  context 'with view all link' do
    let(:documents) { create_list(:document, 6, uploaded_by: user, space: space) }
    
    it 'shows view all link when there are more documents' do
      widget_data[:config][:limit] = 5
      widget_data[:data][:total_count] = 10
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_link('Voir tous les documents', href: '/ged/my-documents')
    end
  end
end