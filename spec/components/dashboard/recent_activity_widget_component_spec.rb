require 'rails_helper'

RSpec.describe Dashboard::RecentActivityWidgetComponent, type: :component do
  let(:user) { create(:user) }
  let(:activities) { [] }
  let(:component) { described_class.new(activities: activities, user: user) }
  
  describe '#render' do
    context 'when there are no activities' do
      it 'displays empty state' do
        render_inline(component)
        
        expect(page).to have_text('Aucune activité récente')
        expect(page).to have_text('Commencez par ajouter ou consulter des documents')
        expect(page).to have_link('Explorer la GED')
      end
    end
    
    context 'when there are recent activities' do
      let(:uploaded_document) { create(:document, uploaded_by: user, created_at: 1.hour.ago) }
      let(:viewed_document) { create(:document) }
      let(:activities) { [uploaded_document, viewed_document] }
      
      it 'displays the activity timeline' do
        render_inline(component)
        
        expect(page).to have_text('Activité récente')
        expect(page).to have_text(uploaded_document.name)
        expect(page).to have_text(viewed_document.name)
      end
      
      it 'shows activity descriptions' do
        render_inline(component)
        
        expect(page).to have_text('Vous avez ajouté ce document')
      end
      
      it 'displays document links' do
        render_inline(component)
        
        expect(page).to have_link(uploaded_document.name)
        expect(page).to have_link(viewed_document.name)
      end
      
      it 'shows link to view all activities' do
        render_inline(component)
        
        expect(page).to have_link('Voir tout')
      end
    end
    
    context 'with different activity types' do
      let(:document) { create(:document) }
      let(:activities) { [document] }
      
      it 'shows upload icon for recently uploaded documents' do
        allow(document).to receive(:uploaded_by).and_return(user)
        allow(document).to receive(:created_at).and_return(1.hour.ago)
        
        render_inline(component)
        
        expect(page).to have_css('svg')
      end
      
      it 'displays document type labels' do
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document.file).to receive(:content_type).and_return('application/pdf')
        
        render_inline(component)
        
        expect(page).to have_text('PDF')
      end
    end
    
    context 'with document thumbnails' do
      let(:document_with_thumbnail) do
        doc = create(:document, uploaded_by: user, created_at: 1.hour.ago)
        allow(doc).to receive(:thumbnail_url).and_return('/fake-thumbnail.jpg')
        doc
      end
      let(:activities) { [document_with_thumbnail] }
      
      it 'displays thumbnail when available' do
        render_inline(component)
        
        expect(page).to have_css('img[src="/fake-thumbnail.jpg"]')
      end
    end
  end
  
  describe 'helper methods' do
    subject { component }
    
    describe '#time_ago_description' do
      it 'formats time correctly' do
        expect(subject.send(:time_ago_description, Time.current)).to eq("à l'instant")
        expect(subject.send(:time_ago_description, 30.seconds.ago)).to match(/il y a \d+ secondes/)
        expect(subject.send(:time_ago_description, 5.minutes.ago)).to match(/il y a \d+ minutes?/)
        expect(subject.send(:time_ago_description, 2.hours.ago)).to match(/il y a \d+ heures?/)
        expect(subject.send(:time_ago_description, 1.day.ago)).to eq('hier')
        expect(subject.send(:time_ago_description, 3.days.ago)).to match(/il y a \d+ jours/)
        expect(subject.send(:time_ago_description, 2.weeks.ago)).to match(/le \d+\/\d+\/\d+/)
      end
    end
    
    describe '#document_type_label' do
      let(:document) { create(:document) }
      
      it 'returns correct label for content types' do
        allow(document.file).to receive(:attached?).and_return(true)
        
        allow(document.file).to receive(:content_type).and_return('application/pdf')
        expect(subject.send(:document_type_label, document)).to eq('PDF')
        
        allow(document.file).to receive(:content_type).and_return('application/vnd.ms-word')
        expect(subject.send(:document_type_label, document)).to eq('Word')
        
        allow(document.file).to receive(:content_type).and_return('image/jpeg')
        expect(subject.send(:document_type_label, document)).to eq('Image')
      end
      
      it 'returns Document for unknown types' do
        allow(document.file).to receive(:attached?).and_return(false)
        expect(subject.send(:document_type_label, document)).to eq('Document')
      end
    end
  end
end