require 'rails_helper'

RSpec.describe Immo::Promo::FinancialDashboardHelper, type: :helper do
  let(:project) { create(:immo_promo_project) }
  let(:budget) { create(:immo_promo_budget, project: project) }
  
  describe '#financial_summary_cards' do
    before do
      project.total_budget_cents = 10_000_000_00
      project.metadata['financial_data'] = {
        'total_spent' => 4_500_000_00,
        'committed' => 2_000_000_00,
        'invoiced' => 3_800_000_00,
        'paid' => 3_500_000_00
      }
    end
    
    it 'displays key financial metrics' do
      result = helper.financial_summary_cards(project)
      
      expect(result).to have_css('.metric-card', count: 5)
      expect(result).to have_content('Budget: €100,000')
      expect(result).to have_content('Spent: €45,000')
      expect(result).to have_content('Remaining: €35,000')
      expect(result).to have_content('Committed: €20,000')
    end
    
    it 'shows utilization percentage' do
      result = helper.financial_summary_cards(project)
      
      expect(result).to have_content('65% utilized') # (spent + committed) / budget
      expect(result).to have_css('.utilization-indicator[data-percentage="65"]')
    end
  end
  
  describe '#cash_flow_chart' do
    before do
      project.metadata['cash_flow'] = {
        'monthly_data' => [
          { 'month' => 'Jan', 'inflow' => 500_000_00, 'outflow' => 300_000_00 },
          { 'month' => 'Feb', 'inflow' => 600_000_00, 'outflow' => 450_000_00 },
          { 'month' => 'Mar', 'inflow' => 400_000_00, 'outflow' => 500_000_00 }
        ]
      }
    end
    
    it 'renders cash flow visualization' do
      result = helper.cash_flow_chart(project)
      
      expect(result).to have_css('.cash-flow-chart')
      expect(result).to have_css('[data-chart-type="cash-flow"]')
      expect(result).to have_content('Net: +€2,000') # Jan
      expect(result).to have_content('Net: +€1,500') # Feb
      expect(result).to have_content('Net: -€1,000') # Mar
    end
    
    it 'highlights negative cash flow periods' do
      result = helper.cash_flow_chart(project)
      
      expect(result).to have_css('.negative-flow')
    end
  end
  
  describe '#budget_burn_rate' do
    it 'calculates and displays burn rate' do
      project.start_date = 3.months.ago
      project.end_date = 9.months.from_now
      project.total_budget_cents = 12_000_000_00
      project.metadata['total_spent'] = 3_000_000_00
      
      result = helper.budget_burn_rate(project)
      
      expect(result).to have_content('Burn rate: €10,000/month')
      expect(result).to have_content('Projected completion: On budget')
      expect(result).to have_css('.burn-rate-indicator')
    end
    
    it 'warns about high burn rate' do
      project.start_date = 2.months.ago
      project.end_date = 4.months.from_now
      project.total_budget_cents = 6_000_000_00
      project.metadata['total_spent'] = 3_000_000_00
      
      result = helper.budget_burn_rate(project)
      
      expect(result).to have_css('.burn-rate-warning')
      expect(result).to have_content('Over budget risk')
    end
  end
  
  describe '#payment_schedule_timeline' do
    let(:payment_milestones) do
      [
        { date: 1.month.ago, amount: 1_000_000_00, status: 'paid', description: 'Initial payment' },
        { date: Date.current, amount: 2_000_000_00, status: 'due', description: 'Phase 1 completion' },
        { date: 2.months.from_now, amount: 1_500_000_00, status: 'scheduled', description: 'Phase 2 completion' }
      ]
    end
    
    it 'displays payment timeline' do
      result = helper.payment_schedule_timeline(payment_milestones)
      
      expect(result).to have_css('.payment-timeline')
      expect(result).to have_css('.payment-milestone', count: 3)
      expect(result).to have_css('.status-paid')
      expect(result).to have_css('.status-due')
      expect(result).to have_css('.status-scheduled')
    end
    
    it 'shows payment amounts and descriptions' do
      result = helper.payment_schedule_timeline(payment_milestones)
      
      expect(result).to have_content('€10,000')
      expect(result).to have_content('€20,000')
      expect(result).to have_content('Initial payment')
    end
  end
  
  describe '#cost_breakdown_chart' do
    before do
      create(:immo_promo_budget_line, budget: budget, category: 'construction', actual_amount_cents: 5_000_000_00)
      create(:immo_promo_budget_line, budget: budget, category: 'design', actual_amount_cents: 1_000_000_00)
      create(:immo_promo_budget_line, budget: budget, category: 'permits', actual_amount_cents: 500_000_00)
      create(:immo_promo_budget_line, budget: budget, category: 'marketing', actual_amount_cents: 300_000_00)
    end
    
    it 'shows cost distribution by category' do
      result = helper.cost_breakdown_chart(budget)
      
      expect(result).to have_css('.cost-breakdown')
      expect(result).to have_content('Construction: 73.5%')
      expect(result).to have_content('Design: 14.7%')
      expect(result).to have_content('Permits: 7.4%')
      expect(result).to have_content('Marketing: 4.4%')
    end
  end
  
  describe '#financial_health_indicators' do
    it 'displays financial health metrics' do
      indicators = {
        liquidity_ratio: 1.5,
        debt_to_equity: 0.4,
        roi_projection: 18.5,
        payback_period: 4.2
      }
      
      result = helper.financial_health_indicators(indicators)
      
      expect(result).to have_css('.health-indicator', count: 4)
      expect(result).to have_css('.indicator-good') # liquidity > 1
      expect(result).to have_content('Liquidity: 1.5')
      expect(result).to have_content('ROI: 18.5%')
      expect(result).to have_content('Payback: 4.2 years')
    end
  end
  
  describe '#variance_analysis_table' do
    before do
      create(:immo_promo_budget_line, 
        budget: budget,
        category: 'construction',
        planned_amount_cents: 5_000_000_00,
        actual_amount_cents: 5_500_000_00
      )
      create(:immo_promo_budget_line,
        budget: budget,
        category: 'design',
        planned_amount_cents: 1_000_000_00,
        actual_amount_cents: 900_000_00
      )
    end
    
    it 'shows budget vs actual comparison' do
      result = helper.variance_analysis_table(budget)
      
      expect(result).to have_css('table.variance-analysis')
      expect(result).to have_css('tr', count: 3) # header + 2 lines
      expect(result).to have_content('+€5,000') # construction overage
      expect(result).to have_content('-€1,000') # design savings
    end
  end
  
  describe '#financial_alerts' do
    it 'displays financial warnings and alerts' do
      alerts = [
        { type: 'overspend', message: 'Construction budget exceeded by 10%', severity: 'high' },
        { type: 'payment_due', message: 'Invoice payment due in 3 days', severity: 'medium' },
        { type: 'forecast', message: 'Projected to be within budget', severity: 'low' }
      ]
      
      result = helper.financial_alerts(alerts)
      
      expect(result).to have_css('.financial-alert', count: 3)
      expect(result).to have_css('.alert-high')
      expect(result).to have_css('.alert-medium')
      expect(result).to have_css('.alert-low')
    end
  end
end