require 'rails_helper'

RSpec.describe Immo::Promo::RiskMonitoringHelper, type: :helper do
  let(:project) { create(:immo_promo_project) }
  let(:risk) { create(:immo_promo_risk, project: project) }
  
  describe '#risk_matrix_cell' do
    it 'returns appropriate color for risk severity' do
      expect(helper.risk_matrix_cell('high', 'high')).to have_css('.risk-critical')
      expect(helper.risk_matrix_cell('medium', 'medium')).to have_css('.risk-moderate')
      expect(helper.risk_matrix_cell('low', 'low')).to have_css('.risk-low')
    end
    
    it 'calculates combined risk level' do
      result = helper.risk_matrix_cell('high', 'medium')
      expect(result).to have_css('.risk-high')
      expect(result).to have_content('High Risk')
    end
  end
  
  describe '#risk_trend_indicator' do
    it 'shows increasing risk trend' do
      risk.metadata['trend'] = 'increasing'
      risk.metadata['trend_percentage'] = 25
      
      result = helper.risk_trend_indicator(risk)
      
      expect(result).to have_css('.trend-up.text-danger')
      expect(result).to have_content('+25%')
    end
    
    it 'shows decreasing risk trend' do
      risk.metadata['trend'] = 'decreasing'
      risk.metadata['trend_percentage'] = -15
      
      result = helper.risk_trend_indicator(risk)
      
      expect(result).to have_css('.trend-down.text-success')
      expect(result).to have_content('-15%')
    end
  end
  
  describe '#risk_mitigation_status' do
    it 'displays mitigation progress' do
      risk.metadata['mitigation_actions'] = [
        { 'action' => 'Insurance coverage', 'status' => 'completed' },
        { 'action' => 'Safety protocols', 'status' => 'in_progress' },
        { 'action' => 'Contingency plan', 'status' => 'pending' }
      ]
      
      result = helper.risk_mitigation_status(risk)
      
      expect(result).to have_content('1/3 completed')
      expect(result).to have_css('.mitigation-progress')
    end
  end
  
  describe '#risk_impact_areas' do
    it 'shows affected project areas' do
      risk.impact_areas = ['budget', 'timeline', 'quality']
      
      result = helper.risk_impact_areas(risk)
      
      expect(result).to have_css('.impact-tag', count: 3)
      expect(result).to have_content('Budget')
      expect(result).to have_content('Timeline')
      expect(result).to have_content('Quality')
    end
  end
  
  describe '#risk_score_badge' do
    it 'displays calculated risk score' do
      risk.probability = 'high'
      risk.impact = 'high'
      
      result = helper.risk_score_badge(risk)
      
      expect(result).to have_css('.badge.badge-danger')
      expect(result).to have_content('9') # High probability * High impact
    end
  end
  
  describe '#risk_owner_info' do
    let(:owner) { create(:user, first_name: 'Jane', last_name: 'Smith') }
    
    it 'displays risk owner details' do
      risk.metadata['owner_id'] = owner.id
      allow(helper).to receive(:user_path).and_return('/users/1')
      
      result = helper.risk_owner_info(risk)
      
      expect(result).to have_link('Jane Smith', href: '/users/1')
      expect(result).to have_css('.owner-avatar')
    end
  end
  
  describe '#risk_review_schedule' do
    it 'shows next review date' do
      risk.metadata['next_review_date'] = 1.week.from_now.to_date.to_s
      risk.metadata['review_frequency'] = 'weekly'
      
      result = helper.risk_review_schedule(risk)
      
      expect(result).to have_content('Next review in 7 days')
      expect(result).to have_content('Weekly reviews')
    end
    
    it 'highlights overdue reviews' do
      risk.metadata['next_review_date'] = 3.days.ago.to_date.to_s
      
      result = helper.risk_review_schedule(risk)
      
      expect(result).to have_css('.text-danger')
      expect(result).to have_content('Review overdue by 3 days')
    end
  end
end