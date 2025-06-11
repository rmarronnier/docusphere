require 'rails_helper'

RSpec.describe Immo::Promo::BudgetLinesHelper, type: :helper do
  let(:budget) { create(:immo_promo_budget) }
  let(:budget_line) { create(:immo_promo_budget_line, budget: budget) }
  
  describe '#budget_line_category_icon' do
    it 'returns appropriate icon for each category' do
      expect(helper.budget_line_category_icon('construction')).to have_css('.icon-building')
      expect(helper.budget_line_category_icon('design')).to have_css('.icon-palette')
      expect(helper.budget_line_category_icon('permits')).to have_css('.icon-document-text')
      expect(helper.budget_line_category_icon('marketing')).to have_css('.icon-megaphone')
      expect(helper.budget_line_category_icon('other')).to have_css('.icon-dots-horizontal')
    end
  end
  
  describe '#budget_line_variance' do
    context 'with actual amount' do
      before do
        budget_line.planned_amount_cents = 100_000_00
        budget_line.actual_amount_cents = 85_000_00
      end
      
      it 'displays variance amount and percentage' do
        result = helper.budget_line_variance(budget_line)
        
        expect(result).to have_css('.variance.positive')
        expect(result).to have_content('€1,500.00')
        expect(result).to have_content('-15%')
      end
    end
    
    context 'with overspend' do
      before do
        budget_line.planned_amount_cents = 100_000_00
        budget_line.actual_amount_cents = 120_000_00
      end
      
      it 'displays negative variance' do
        result = helper.budget_line_variance(budget_line)
        
        expect(result).to have_css('.variance.negative')
        expect(result).to have_content('€2,000.00')
        expect(result).to have_content('+20%')
      end
    end
    
    context 'without actual amount' do
      before { budget_line.actual_amount_cents = nil }
      
      it 'displays no variance' do
        result = helper.budget_line_variance(budget_line)
        
        expect(result).to have_content('No actual data')
      end
    end
  end
  
  describe '#budget_line_progress' do
    it 'shows spending progress bar' do
      budget_line.planned_amount_cents = 100_000_00
      budget_line.actual_amount_cents = 75_000_00
      
      result = helper.budget_line_progress(budget_line)
      
      expect(result).to have_css('.progress-bar[style*="width: 75%"]')
      expect(result).to have_content('75% spent')
    end
    
    it 'indicates overspending' do
      budget_line.planned_amount_cents = 100_000_00
      budget_line.actual_amount_cents = 130_000_00
      
      result = helper.budget_line_progress(budget_line)
      
      expect(result).to have_css('.progress-bar.bg-danger[style*="width: 100%"]')
      expect(result).to have_content('130% - Over budget')
    end
  end
  
  describe '#budget_line_status' do
    it 'returns status based on spending' do
      budget_line.planned_amount_cents = 100_000_00
      
      budget_line.actual_amount_cents = 50_000_00
      expect(helper.budget_line_status(budget_line)).to eq('on_track')
      
      budget_line.actual_amount_cents = 95_000_00
      expect(helper.budget_line_status(budget_line)).to eq('at_risk')
      
      budget_line.actual_amount_cents = 110_000_00
      expect(helper.budget_line_status(budget_line)).to eq('over_budget')
    end
  end
  
  describe '#format_budget_line_period' do
    it 'formats budget line time period' do
      budget_line.start_date = Date.new(2025, 1, 1)
      budget_line.end_date = Date.new(2025, 3, 31)
      
      expect(helper.format_budget_line_period(budget_line)).to eq('Q1 2025')
    end
    
    it 'handles custom periods' do
      budget_line.start_date = Date.new(2025, 2, 15)
      budget_line.end_date = Date.new(2025, 4, 15)
      
      expect(helper.format_budget_line_period(budget_line)).to eq('Feb 15 - Apr 15, 2025')
    end
  end
  
  describe '#budget_line_allocation_chart' do
    it 'generates allocation breakdown' do
      budget_line.metadata = {
        'allocations' => [
          { 'name' => 'Labor', 'amount' => 60000 },
          { 'name' => 'Materials', 'amount' => 30000 },
          { 'name' => 'Equipment', 'amount' => 10000 }
        ]
      }
      
      result = helper.budget_line_allocation_chart(budget_line)
      
      expect(result).to have_css('.allocation-chart')
      expect(result).to have_content('Labor: 60%')
      expect(result).to have_content('Materials: 30%')
      expect(result).to have_content('Equipment: 10%')
    end
  end
  
  describe '#budget_line_notes_indicator' do
    it 'shows notes presence' do
      budget_line.notes = 'Important budget considerations'
      
      result = helper.budget_line_notes_indicator(budget_line)
      
      expect(result).to have_css('.icon-annotation')
      expect(result).to have_css('[title*="Notes available"]')
    end
    
    it 'returns nil when no notes' do
      budget_line.notes = nil
      
      expect(helper.budget_line_notes_indicator(budget_line)).to be_nil
    end
  end
  
  describe '#budget_lines_summary' do
    before do
      create(:immo_promo_budget_line, budget: budget, 
        category: 'construction', 
        planned_amount_cents: 600_000_00,
        actual_amount_cents: 550_000_00
      )
      create(:immo_promo_budget_line, budget: budget,
        category: 'design',
        planned_amount_cents: 200_000_00,
        actual_amount_cents: 210_000_00
      )
    end
    
    it 'provides budget lines overview' do
      result = helper.budget_lines_summary(budget)
      
      expect(result[:total_lines]).to eq(2)
      expect(result[:total_planned]).to eq(800_000_00)
      expect(result[:total_actual]).to eq(760_000_00)
      expect(result[:variance]).to eq(-40_000_00)
      expect(result[:variance_percentage]).to eq(-5.0)
    end
  end
end