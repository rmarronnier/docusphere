require 'rails_helper'

RSpec.describe Documents::AiInsightsComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space) }
  let(:component) { described_class.new(document: document) }

  describe '#initialize' do
    it 'sets the document' do
      expect(component.instance_variable_get(:@document)).to eq(document)
    end
  end

  describe '#show_ai_insights?' do
    it 'returns true when document is AI processed' do
      allow(document).to receive(:ai_processed?).and_return(true)
      expect(component.send(:show_ai_insights?)).to be true
    end

    it 'returns false when document is not AI processed' do
      allow(document).to receive(:ai_processed?).and_return(false)
      expect(component.send(:show_ai_insights?)).to be false
    end
  end

  describe '#classification_badge_color' do
    it 'returns green for high confidence (80-100%)' do
      allow(document).to receive(:ai_classification_confidence_percent).and_return(90)
      expect(component.send(:classification_badge_color)).to eq('bg-green-100 text-green-800')
    end

    it 'returns yellow for good confidence (60-79%)' do
      allow(document).to receive(:ai_classification_confidence_percent).and_return(70)
      expect(component.send(:classification_badge_color)).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns orange for moderate confidence (40-59%)' do
      allow(document).to receive(:ai_classification_confidence_percent).and_return(50)
      expect(component.send(:classification_badge_color)).to eq('bg-orange-100 text-orange-800')
    end

    it 'returns red for low confidence (below 40%)' do
      allow(document).to receive(:ai_classification_confidence_percent).and_return(30)
      expect(component.send(:classification_badge_color)).to eq('bg-red-100 text-red-800')
    end
  end

  describe '#confidence_level_text' do
    it 'returns "Très fiable" for high confidence' do
      allow(document).to receive(:ai_classification_confidence_percent).and_return(85)
      expect(component.send(:confidence_level_text)).to eq('Très fiable')
    end

    it 'returns "Fiable" for good confidence' do
      allow(document).to receive(:ai_classification_confidence_percent).and_return(65)
      expect(component.send(:confidence_level_text)).to eq('Fiable')
    end

    it 'returns "Modérée" for moderate confidence' do
      allow(document).to receive(:ai_classification_confidence_percent).and_return(45)
      expect(component.send(:confidence_level_text)).to eq('Modérée')
    end

    it 'returns "Faible" for low confidence' do
      allow(document).to receive(:ai_classification_confidence_percent).and_return(25)
      expect(component.send(:confidence_level_text)).to eq('Faible')
    end
  end

  describe '#entity_icon' do
    it 'returns specific icon for email entity' do
      icon = component.send(:entity_icon, 'email')
      expect(icon).to include('M3 8l7.89')
    end

    it 'returns specific icon for phone entity' do
      icon = component.send(:entity_icon, 'phone')
      expect(icon).to include('M3 5a2 2 0')
    end

    it 'returns specific icon for date entity' do
      icon = component.send(:entity_icon, 'date')
      expect(icon).to include('M8 7V3m8 4V3')
    end

    it 'returns default organization icon for unknown entity' do
      icon = component.send(:entity_icon, 'unknown_type')
      expect(icon).to include('M19 21V5a2 2 0')
    end
  end

  describe '#entity_color' do
    it 'returns blue for email entity' do
      expect(component.send(:entity_color, 'email')).to eq('text-blue-600')
    end

    it 'returns green for phone entity' do
      expect(component.send(:entity_color, 'phone')).to eq('text-green-600')
    end

    it 'returns purple for date entity' do
      expect(component.send(:entity_color, 'date')).to eq('text-purple-600')
    end

    it 'returns gray for unknown entity' do
      expect(component.send(:entity_color, 'unknown_type')).to eq('text-gray-600')
    end
  end

  describe '#category_description' do
    it 'returns description for invoice category' do
      expect(component.send(:category_description, 'invoice')).to eq('Document de facturation')
    end

    it 'returns description for contract category' do
      expect(component.send(:category_description, 'contract')).to eq('Contrat ou accord')
    end

    it 'returns description for report category' do
      expect(component.send(:category_description, 'report')).to eq('Rapport ou étude')
    end

    it 'returns default description for unknown category' do
      expect(component.send(:category_description, 'unknown_category')).to eq('Type de document')
    end
  end

  describe 'rendering' do
    context 'when document is AI processed' do
      let(:document) { 
        doc = create(:document)
        allow(doc).to receive(:ai_processed?).and_return(true)
        allow(doc).to receive(:ai_classification_confidence_percent).and_return(85)
        allow(doc).to receive(:ai_summary).and_return('This is a test document summary')
        allow(doc).to receive(:ai_classification_category).and_return('contract')
        allow(doc).to receive(:ai_entities_by_type).and_return([])
        allow(doc).to receive(:ai_confidence).and_return(0.85)
        allow(doc).to receive(:ai_processed_at).and_return(Time.current)
        allow(doc).to receive(:extracted_text).and_return('This is the extracted text from the document')
        allow(doc).to receive(:supports_ai_processing?).and_return(true)
        allow(doc).to receive_message_chain(:ai_entities, :present?).and_return(false)
        doc
      }

      it 'renders the component' do
        render_inline(component)
        
        expect(page).to have_text('Analyse IA du document')
        expect(page).to have_text('Contrat ou accord') # category description
        expect(page).to have_text('85%') # confidence percentage
        expect(page).to have_text('Très fiable') # confidence level
        expect(page).to have_text('This is a test document summary') # ai summary
        expect(page).to have_text('This is the extracted text') # extracted text
      end
    end

    context 'when document is not AI processed' do
      before do
        allow(document).to receive(:ai_processed?).and_return(false)
      end

      it 'does not show insights when not processed' do
        expect(component.send(:show_ai_insights?)).to be false
      end
    end
  end
end