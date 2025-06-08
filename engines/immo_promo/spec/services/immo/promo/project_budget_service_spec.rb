require 'rails_helper'

RSpec.describe Immo::Promo::ProjectBudgetService do
  let(:organization) { create(:organization) }
  let(:project) do
    create(:immo_promo_project,
      organization: organization,
      total_budget_cents: 1_000_000_00,
      current_budget_cents: 300_000_00,
      start_date: 2.months.ago,
      expected_completion_date: 10.months.from_now
    )
  end
  let(:service) { described_class.new(project) }
  
  describe '#budget_summary' do
    let!(:budget) { create(:immo_promo_budget, project: project, fiscal_year: Date.current.year) }
    let!(:budget_lines) do
      [
        create(:immo_promo_budget_line,
          budget: budget,
          category: 'construction_work',
          planned_amount_cents: 500_000_00,
          actual_amount_cents: 150_000_00,
          committed_amount_cents: 100_000_00
        ),
        create(:immo_promo_budget_line,
          budget: budget,
          category: 'studies',
          planned_amount_cents: 200_000_00,
          actual_amount_cents: 180_000_00,
          committed_amount_cents: 20_000_00
        )
      ]
    end
    
    it 'provides comprehensive budget summary' do
      summary = service.budget_summary
      
      expect(summary).to include(
        :allocated,
        :used,
        :remaining,
        :percentage_used,
        :is_over_budget,
        :budgets,
        :forecast,
        :alerts
      )
    end
    
    it 'calculates budget percentages correctly' do
      summary = service.budget_summary
      
      expect(summary[:percentage_used]).to eq(30.0)
      expect(summary[:is_over_budget]).to be false
    end
    
    it 'includes detailed budget breakdown' do
      summary = service.budget_summary
      
      expect(summary[:budgets]).to be_an(Array)
      budget_detail = summary[:budgets].first
      
      expect(budget_detail).to include(
        :id,
        :category,
        :fiscal_year,
        :lines,
        :totals,
        :variance_analysis
      )
    end
  end
  
  describe '#cost_tracking_report' do
    let!(:phases) do
      [
        create(:immo_promo_phase, project: project, phase_type: 'studies'),
        create(:immo_promo_phase, project: project, phase_type: 'construction')
      ]
    end
    
    let!(:budget) { create(:immo_promo_budget, project: project) }
    let!(:budget_lines) do
      create_list(:immo_promo_budget_line, 5,
        budget: budget,
        planned_amount_cents: 100_000_00,
        actual_amount_cents: 80_000_00
      )
    end
    
    it 'tracks costs by phase' do
      report = service.cost_tracking_report
      
      expect(report[:by_phase]).to be_a(Hash)
      expect(report[:by_phase]).to have_key(phases.first.name)
    end
    
    it 'tracks costs by category' do
      report = service.cost_tracking_report
      
      expect(report[:by_category]).to be_a(Hash)
    end
    
    it 'identifies top expenses' do
      report = service.cost_tracking_report
      
      expect(report[:top_expenses]).to be_an(Array)
      expect(report[:top_expenses].size).to be <= 10
    end
    
    it 'identifies cost overruns' do
      # Create overrun
      create(:immo_promo_budget_line,
        budget: budget,
        category: 'administrative',
        planned_amount_cents: 50_000_00,
        actual_amount_cents: 75_000_00
      )
      
      report = service.cost_tracking_report
      
      expect(report[:cost_overruns]).not_to be_empty
      overrun = report[:cost_overruns].first
      expect(overrun[:category]).to eq('administrative')
      expect(overrun[:overrun_percentage]).to eq(50.0)
    end
  end
  
  describe '#budget_forecast' do
    it 'calculates burn rate' do
      forecast = service.budget_forecast
      
      expect(forecast[:current_burn_rate]).to be_a(Money)
      expect(forecast[:current_burn_rate]).to be > Money.new(0, 'EUR')
    end
    
    it 'projects completion budget' do
      forecast = service.budget_forecast
      
      expect(forecast[:projected_completion_budget]).to be_a(Money)
      expect(forecast[:projected_total_cost]).to be_a(Money)
    end
    
    it 'provides scenarios' do
      forecast = service.budget_forecast
      
      expect(forecast[:scenarios]).to include(
        :optimistic,
        :realistic,
        :pessimistic
      )
      
      expect(forecast[:scenarios][:optimistic][:burn_rate]).to be < forecast[:scenarios][:pessimistic][:burn_rate]
    end
    
    it 'assesses confidence level' do
      forecast = service.budget_forecast
      
      expect(forecast[:confidence_level]).to be_in(['low', 'medium', 'high'])
    end
  end
  
  describe '#budget_optimization_suggestions' do
    context 'with high variance categories' do
      let!(:budget) { create(:immo_promo_budget, project: project) }
      
      before do
        create(:immo_promo_budget_line,
          budget: budget,
          category: 'equipment',
          planned_amount_cents: 200_000_00,
          actual_amount_cents: 50_000_00
        )
      end
      
      it 'suggests budget reallocation' do
        suggestions = service.budget_optimization_suggestions
        
        reallocation = suggestions.find { |s| s[:type] == 'underutilized_budget' }
        expect(reallocation).to be_present
      end
    end
    
    context 'with cost overruns' do
      let!(:budget) { create(:immo_promo_budget, project: project) }
      
      before do
        create(:immo_promo_budget_line,
          budget: budget,
          category: 'construction_work',
          planned_amount_cents: 100_000_00,
          actual_amount_cents: 150_000_00
        )
      end
      
      it 'suggests cost control measures' do
        suggestions = service.budget_optimization_suggestions
        
        expect(suggestions).not_to be_empty
      end
    end
  end
  
  describe '#cash_flow_analysis' do
    let!(:budget) { create(:immo_promo_budget, project: project) }
    let!(:budget_lines) do
      create_list(:immo_promo_budget_line, 3, budget: budget)
    end
    
    it 'calculates monthly cash flow' do
      analysis = service.cash_flow_analysis
      
      expect(analysis[:monthly_cash_flow]).to be_a(Hash)
    end
    
    it 'tracks cumulative spending' do
      analysis = service.cash_flow_analysis
      
      expect(analysis[:cumulative_spending]).to be_an(Array)
      expect(analysis[:cumulative_spending].first).to include(
        :month,
        :amount,
        :percentage_of_budget
      )
    end
    
    it 'calculates liquidity requirements' do
      analysis = service.cash_flow_analysis
      
      expect(analysis[:liquidity_requirements]).to include(
        :next_3_months,
        :next_6_months,
        :peak_requirement
      )
    end
  end
  
  describe 'budget alerts' do
    context 'when over budget' do
      before do
        project.update(current_budget_cents: 1_200_000_00)
      end
      
      it 'generates over budget alert' do
        summary = service.budget_summary
        alerts = summary[:alerts]
        
        over_budget_alert = alerts.find { |a| a[:type] == 'danger' }
        expect(over_budget_alert).to be_present
        expect(over_budget_alert[:title]).to eq('Budget Exceeded')
      end
    end
    
    context 'with high burn rate' do
      before do
        project.update(
          start_date: 6.months.ago,
          current_budget_cents: 800_000_00
        )
      end
      
      it 'generates burn rate warning' do
        summary = service.budget_summary
        alerts = summary[:alerts]
        
        burn_rate_alert = alerts.find { |a| a[:title] == 'High Burn Rate' }
        expect(burn_rate_alert).to be_present
      end
    end
  end
end