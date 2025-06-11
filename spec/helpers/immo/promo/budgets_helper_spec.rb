require 'rails_helper'

RSpec.describe Immo::Promo::BudgetsHelper, type: :helper do
  let(:project) { create(:immo_promo_project) }
  let(:budget) { create(:immo_promo_budget, project: project, planned_amount_cents: 1_000_000_00) }
  
  describe '#budget_variance_indicator' do
    it 'shows positive variance in green' do
      budget.metadata['actual_amount_cents'] = 900_000_00
      result = helper.budget_variance_indicator(budget)
      
      expect(result).to have_css('.text-success')
      expect(result).to have_content('-10%')
      expect(result).to have_content('€10,000 under budget')
    end
    
    it 'shows negative variance in red' do
      budget.metadata['actual_amount_cents'] = 1_150_000_00
      result = helper.budget_variance_indicator(budget)
      
      expect(result).to have_css('.text-danger')
      expect(result).to have_content('+15%')
      expect(result).to have_content('€15,000 over budget')
    end
    
    it 'shows neutral for on-budget' do
      budget.metadata['actual_amount_cents'] = 1_000_000_00
      result = helper.budget_variance_indicator(budget)
      
      expect(result).to have_css('.text-muted')
      expect(result).to have_content('On budget')
    end
  end
  
  describe '#budget_utilization_chart' do
    it 'renders utilization percentage' do
      budget_lines = [
        create(:immo_promo_budget_line, budget: budget, planned_amount_cents: 300_000_00, actual_amount_cents: 250_000_00),
        create(:immo_promo_budget_line, budget: budget, planned_amount_cents: 200_000_00, actual_amount_cents: 180_000_00)
      ]
      
      result = helper.budget_utilization_chart(budget)
      
      expect(result).to have_css('.progress')
      expect(result).to have_content('43%') # (250k + 180k) / 1M
    end
  end
  
  describe '#budget_category_breakdown' do
    before do
      create(:immo_promo_budget_line, budget: budget, category: 'construction', planned_amount_cents: 600_000_00)
      create(:immo_promo_budget_line, budget: budget, category: 'design', planned_amount_cents: 200_000_00)
      create(:immo_promo_budget_line, budget: budget, category: 'permits', planned_amount_cents: 200_000_00)
    end
    
    it 'shows category percentages' do
      result = helper.budget_category_breakdown(budget)
      
      expect(result).to have_content('Construction: 60%')
      expect(result).to have_content('Design: 20%')
      expect(result).to have_content('Permits: 20%')
    end
  end
  
  describe '#format_budget_period' do
    it 'formats budget period range' do
      budget.start_date = Date.new(2025, 1, 1)
      budget.end_date = Date.new(2025, 12, 31)
      
      expect(helper.format_budget_period(budget)).to eq('Jan 2025 - Dec 2025')
    end
  end
  
  describe '#budget_alerts' do
    it 'shows alerts for budget issues' do
      budget.metadata['alerts'] = [
        { type: 'overspend', message: 'Materials category over budget' },
        { type: 'approval_needed', message: 'Budget revision pending approval' }
      ]
      
      result = helper.budget_alerts(budget)
      
      expect(result).to have_css('.alert.alert-warning', count: 2)
      expect(result).to have_content('Materials category over budget')
    end
  end
  
  describe '#budget_approval_status' do
    it 'displays approval workflow status' do
      budget.approval_status = 'pending'
      budget.metadata['approvers'] = [
        { name: 'John Doe', status: 'approved' },
        { name: 'Jane Smith', status: 'pending' }
      ]
      
      result = helper.budget_approval_status(budget)
      
      expect(result).to have_css('.approval-status')
      expect(result).to have_content('1/2 approvals')
    end
  end
end