require 'rails_helper'

RSpec.describe Dashboard::StatisticsWidgetComponent, type: :component do
  let(:stats) do
    {
      total_documents: 42,
      pending_validations: 5,
      shared_documents: 15,
      storage_used: "2.5 GB"
    }
  end
  let(:component) { described_class.new(stats: stats) }
  
  describe '#render' do
    before do
      render_inline(component)
    end
    
    it 'displays the widget title' do
      expect(page).to have_text('Statistiques')
    end
    
    it 'shows all statistics' do
      expect(page).to have_text('Documents totaux')
      expect(page).to have_text('42')
      
      expect(page).to have_text('En attente')
      expect(page).to have_text('5')
      
      expect(page).to have_text('Partagés')
      expect(page).to have_text('15')
      
      expect(page).to have_text('Stockage utilisé')
      expect(page).to have_text('2.5 GB')
      expect(page).to have_text('sur 10 GB')
    end
    
    it 'displays trends' do
      # Component shows mock trend data
      expect(page).to have_text('+12%')
      expect(page).to have_text('-5%')
      expect(page).to have_text('+8%')
    end
    
    it 'shows storage progress bar' do
      expect(page).to have_css('div.bg-gray-200.rounded-full.h-2')
      expect(page).to have_text('25% utilisé') # 2.5GB / 10GB
    end
    
    it 'includes link to detailed statistics' do
      expect(page).to have_link('Voir les statistiques détaillées')
    end
    
    context 'with empty stats' do
      let(:stats) { {} }
      
      it 'handles missing data gracefully' do
        render_inline(component)
        
        expect(page).to have_text('Documents totaux')
        expect(page).to have_text('0')
        expect(page).to have_text('0 B')
      end
    end
  end
  
  describe 'helper methods' do
    subject { component }
    
    describe '#parse_storage_size' do
      it 'parses different storage formats' do
        expect(subject.send(:parse_storage_size, '500 B')).to eq(500)
        expect(subject.send(:parse_storage_size, '1.5 KB')).to eq(1.5.kilobytes)
        expect(subject.send(:parse_storage_size, '2.5 MB')).to eq(2.5.megabytes)
        expect(subject.send(:parse_storage_size, '1.2 GB')).to eq(1.2.gigabytes)
      end
      
      it 'handles invalid input' do
        expect(subject.send(:parse_storage_size, nil)).to eq(0)
        expect(subject.send(:parse_storage_size, 'invalid')).to eq(0)
        expect(subject.send(:parse_storage_size, '')).to eq(0)
      end
    end
    
    describe '#storage_percentage' do
      it 'calculates percentage correctly' do
        component = described_class.new(stats: { storage_used: '2.5 GB' })
        expect(component.send(:storage_percentage)).to eq(25.0)
      end
      
      it 'handles edge cases' do
        component = described_class.new(stats: { storage_used: '0 B' })
        expect(component.send(:storage_percentage)).to eq(0)
        
        component = described_class.new(stats: {})
        expect(component.send(:storage_percentage)).to eq(0)
      end
    end
    
    describe '#trend_for' do
      it 'returns correct trend direction' do
        expect(subject.send(:trend_for, :total_documents)).to eq('up')
        expect(subject.send(:trend_for, :pending_validations)).to eq('down')
        expect(subject.send(:trend_for, :shared_documents)).to eq('up')
      end
    end
  end
  
  describe 'visual elements' do
    it 'displays icons for each statistic' do
      render_inline(component)
      
      # Check for icon containers
      expect(page).to have_css('div.p-2.rounded-full', count: 4)
      
      # Check for SVG icons
      expect(page).to have_css('svg.w-5.h-5', minimum: 4)
    end
    
    it 'applies correct color classes' do
      render_inline(component)
      
      expect(page).to have_css('.text-blue-600')
      expect(page).to have_css('.text-orange-600')
      expect(page).to have_css('.text-purple-600')
      expect(page).to have_css('.text-green-600')
    end
  end
end