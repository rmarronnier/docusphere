require 'rails_helper'

RSpec.describe Immo::Promo::VarianceAnalyzable do
  # Create a test controller to test the concern
  controller(ApplicationController) do
    include Immo::Promo::VarianceAnalyzable
    
    def test_analyze_variance
      budget_lines = [
        { name: 'Terrassement', planned_amount: 100000, actual_amount: 110000 },
        { name: 'Fondations', planned_amount: 200000, actual_amount: 195000 },
        { name: 'Gros œuvre', planned_amount: 500000, actual_amount: 600000 }
      ]
      
      current_budget = 905000
      total_budget = 800000
      
      render json: analyze_budget_variance(budget_lines, current_budget, total_budget)
    end
    
    def test_variance_trends
      historical_data = [
        { date: '2025-01', variance: 5.0, previous_variance: nil },
        { date: '2025-02', variance: 8.0, previous_variance: 5.0 },
        { date: '2025-03', variance: 7.5, previous_variance: 8.0 }
      ]
      
      render json: analyze_variance_trends(historical_data)
    end
  end

  before do
    routes.draw do
      get 'test_analyze_variance' => 'anonymous#test_analyze_variance'
      get 'test_variance_trends' => 'anonymous#test_variance_trends'
    end
  end

  describe '#analyze_budget_variance' do
    it 'calculates overall variance correctly' do
      get :test_analyze_variance
      result = JSON.parse(response.body)
      
      expect(result['variance']).to eq(105000)
      expect(result['variance_percentage']).to eq(13.12)
      expect(result['status']).to eq('warning')
    end
    
    it 'analyzes line variances' do
      get :test_analyze_variance
      result = JSON.parse(response.body)
      
      line_variances = result['by_line']
      expect(line_variances[0]['variance_percentage']).to eq(10.0)
      expect(line_variances[0]['variance_category']).to eq('concerning')
      
      expect(line_variances[1]['variance_percentage']).to eq(-2.5)
      expect(line_variances[1]['variance_category']).to eq('acceptable')
      
      expect(line_variances[2]['variance_percentage']).to eq(20.0)
      expect(line_variances[2]['variance_category']).to eq('critical')
    end
    
    it 'identifies variance drivers' do
      get :test_analyze_variance
      result = JSON.parse(response.body)
      
      expect(result['drivers']).to include('Consommation budgétaire accélérée')
      expect(result['drivers']).to include('Surveillance renforcée recommandée')
    end
    
    it 'suggests corrective actions' do
      get :test_analyze_variance
      result = JSON.parse(response.body)
      
      actions = result['corrective_actions']
      expect(actions).to be_an(Array)
      expect(actions.first['urgency']).to eq('medium')
    end
  end

  describe '#determine_variance_status' do
    it 'returns on_track for small variances' do
      expect(controller.send(:determine_variance_status, 3.5)).to eq('on_track')
      expect(controller.send(:determine_variance_status, -4.0)).to eq('on_track')
    end
    
    it 'returns warning for moderate variances' do
      expect(controller.send(:determine_variance_status, 10.0)).to eq('warning')
      expect(controller.send(:determine_variance_status, -12.0)).to eq('warning')
    end
    
    it 'returns critical for large variances' do
      expect(controller.send(:determine_variance_status, 20.0)).to eq('critical')
      expect(controller.send(:determine_variance_status, -25.0)).to eq('critical')
    end
  end

  describe '#categorize_variance' do
    it 'categorizes variances correctly' do
      expect(controller.send(:categorize_variance, 3.0)).to eq('acceptable')
      expect(controller.send(:categorize_variance, 10.0)).to eq('concerning')
      expect(controller.send(:categorize_variance, 20.0)).to eq('critical')
    end
  end

  describe '#assess_variance_impact' do
    it 'assesses project impact based on amount' do
      line_high = { planned_amount: 100000, actual_amount: 160000 }
      line_low = { planned_amount: 100000, actual_amount: 110000 }
      
      impact_high = controller.send(:assess_variance_impact, line_high)
      impact_low = controller.send(:assess_variance_impact, line_low)
      
      expect(impact_high[:project_impact]).to eq('high')
      expect(impact_low[:project_impact]).to eq('low')
    end
    
    it 'identifies potential delays for large negative variances' do
      line = { planned_amount: 100000, actual_amount: 70000 }
      impact = controller.send(:assess_variance_impact, line)
      
      expect(impact[:timeline_impact]).to eq('potential_delay')
    end
  end

  describe '#analyze_variance_trends' do
    it 'analyzes trends correctly' do
      get :test_variance_trends
      result = JSON.parse(response.body)
      
      expect(result).to be_an(Array)
      expect(result[0]['trend']).to eq('stable')
      expect(result[1]['trend']).to eq('deteriorating')
      expect(result[2]['trend']).to eq('improving')
    end
  end

  describe '#suggest_corrective_actions' do
    it 'suggests high urgency actions for critical overruns' do
      actions = controller.send(:suggest_corrective_actions, 20.0)
      
      expect(actions).to be_an(Array)
      expect(actions.first[:urgency]).to eq('high')
      expect(actions.first[:action]).to include('Réviser')
    end
    
    it 'suggests medium urgency actions for moderate overruns' do
      actions = controller.send(:suggest_corrective_actions, 10.0)
      
      expect(actions.first[:urgency]).to eq('medium')
      expect(actions.first[:action]).to include('Analyser')
    end
    
    it 'suggests acceleration for significant underruns' do
      actions = controller.send(:suggest_corrective_actions, -20.0)
      
      expect(actions.first[:action]).to include('Accélérer')
      expect(actions.first[:responsible]).to eq('project_manager')
    end
  end

  describe '#calculate_trend_direction' do
    it 'identifies improving trends' do
      trend = controller.send(:calculate_trend_direction, 5.0, 10.0)
      expect(trend).to eq('improving')
    end
    
    it 'identifies deteriorating trends' do
      trend = controller.send(:calculate_trend_direction, 15.0, 10.0)
      expect(trend).to eq('deteriorating')
    end
    
    it 'identifies stable trends' do
      trend = controller.send(:calculate_trend_direction, 10.5, 10.0)
      expect(trend).to eq('stable')
    end
  end
end