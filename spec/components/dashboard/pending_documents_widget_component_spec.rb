require 'rails_helper'

RSpec.describe Dashboard::PendingDocumentsWidgetComponent, type: :component do
  let(:user) { create(:user) }
  let(:documents) { [] }
  let(:component) { described_class.new(documents: documents, user: user) }
  
  describe '#render' do
    context 'when there are no pending documents' do
      it 'displays empty state' do
        render_inline(component)
        
        expect(page).to have_text('Aucun document en attente')
        expect(page).to have_text('Tous vos documents sont à jour')
        expect(page).to have_link('Nouveau document')
      end
    end
    
    context 'when there are pending documents' do
      let(:draft_document) { create(:document, status: 'draft', uploaded_by: user) }
      let(:locked_document) { create(:document, status: 'locked', locked_by: user) }
      let(:documents) { [draft_document, locked_document] }
      
      it 'displays the documents list' do
        render_inline(component)
        
        expect(page).to have_text('Documents nécessitant votre attention')
        expect(page).to have_text('2 documents')
        expect(page).to have_text(draft_document.name)
        expect(page).to have_text(locked_document.name)
      end
      
      it 'shows correct status labels' do
        render_inline(component)
        
        expect(page).to have_text('Brouillon')
        expect(page).to have_text('Verrouillé')
      end
      
      it 'shows action buttons for each document' do
        render_inline(component)
        
        expect(page).to have_link('Action', count: 2)
      end
      
      it 'displays link to view all pending documents' do
        render_inline(component)
        
        expect(page).to have_link('Voir tous les documents en attente')
      end
    end
    
    context 'with document thumbnails' do
      let(:document_with_thumbnail) do
        doc = create(:document, status: 'draft', uploaded_by: user)
        allow(doc).to receive(:thumbnail_url).and_return('/fake-thumbnail.jpg')
        doc
      end
      let(:documents) { [document_with_thumbnail] }
      
      it 'displays thumbnail when available' do
        render_inline(component)
        
        expect(page).to have_css('img[src="/fake-thumbnail.jpg"]')
      end
    end
    
    context 'with validation requests' do
      let(:document) { create(:document) }
      let(:validation_request) do
        create(:validation_request, 
               validatable: document,
               assigned_to: user,
               status: 'pending')
      end
      let(:documents) { [document] }
      
      before do
        validation_request # ensure it exists
        allow(document).to receive_message_chain(:validation_requests, :pending, :where)
          .and_return([validation_request])
      end
      
      it 'shows validation action' do
        render_inline(component)
        
        expect(page).to have_text('Valider le document')
      end
    end
  end
  
  describe 'helper methods' do
    subject { component }
    
    describe '#format_file_size' do
      it 'formats bytes correctly' do
        expect(subject.send(:format_file_size, 500)).to eq('500 B')
        expect(subject.send(:format_file_size, 1500)).to eq('1.5 KB')
        expect(subject.send(:format_file_size, 1_500_000)).to eq('1.4 MB')
        expect(subject.send(:format_file_size, 1_500_000_000)).to eq('1.4 GB')
      end
      
      it 'handles nil' do
        expect(subject.send(:format_file_size, nil)).to eq('0 B')
      end
    end
    
    describe '#time_ago_in_words_short' do
      it 'formats time correctly' do
        expect(subject.send(:time_ago_in_words_short, Time.current)).to eq("À l'instant")
        expect(subject.send(:time_ago_in_words_short, 30.seconds.ago)).to match(/Il y a \d+s/)
        expect(subject.send(:time_ago_in_words_short, 5.minutes.ago)).to match(/Il y a \d+m/)
        expect(subject.send(:time_ago_in_words_short, 2.hours.ago)).to match(/Il y a \d+h/)
        expect(subject.send(:time_ago_in_words_short, 3.days.ago)).to match(/Il y a \d+j/)
        expect(subject.send(:time_ago_in_words_short, 2.weeks.ago)).to match(/\d+\/\d+\/\d+/)
      end
    end
  end
end