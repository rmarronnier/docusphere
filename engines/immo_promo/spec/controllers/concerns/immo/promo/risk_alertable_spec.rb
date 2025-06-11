require 'rails_helper'

RSpec.describe Immo::Promo::RiskAlertable do
  # Create a test controller to test the concern
  controller(ApplicationController) do
    include Immo::Promo::RiskAlertable
    
    attr_accessor :project
    
    def test_setup_alerts
      risks = [
        { id: 1, title: 'Risque critique', severity: 'critical', probability: 'high', impact: 'severe' },
        { id: 2, title: 'Risque normal', severity: 'medium', probability: 'medium', impact: 'moderate' },
        { 
          id: 3, 
          title: 'Risque avec actions en retard', 
          severity: 'high', 
          probability: 'medium',
          mitigation_actions: [
            { id: 1, title: 'Action 1', due_date: 1.week.ago, status: 'in_progress' }
          ]
        }
      ]
      
      render json: setup_risk_alerts(risks)
    end
    
    def test_emerging_risks
      render json: detect_emerging_risks_for_project
    end
  end

  before do
    routes.draw do
      get 'test_setup_alerts' => 'anonymous#test_setup_alerts'
      get 'test_emerging_risks' => 'anonymous#test_emerging_risks'
    end
  end

  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }

  describe '#setup_risk_alerts' do
    before do
      controller.project = project
    end

    it 'creates alerts for critical risks' do
      get :test_setup_alerts
      alerts = JSON.parse(response.body)
      
      critical_alerts = alerts.select { |a| a['level'] == 'critical' }
      expect(critical_alerts).not_to be_empty
      expect(critical_alerts.first['title']).to include('ALERTE CRITIQUE')
    end
    
    it 'creates alerts for overdue actions' do
      get :test_setup_alerts
      alerts = JSON.parse(response.body)
      
      overdue_alerts = alerts.select { |a| a['type'] == 'overdue_actions' }
      expect(overdue_alerts).not_to be_empty
      expect(overdue_alerts.first['message']).to include('action(s) d\'atténuation en retard')
    end
    
    it 'includes suggested actions for critical alerts' do
      get :test_setup_alerts
      alerts = JSON.parse(response.body)
      
      critical_alert = alerts.find { |a| a['level'] == 'critical' }
      expect(critical_alert['actions']).to be_an(Array)
      expect(critical_alert['actions'].map { |a| a['action'] }).to include('schedule_crisis_meeting')
    end
  end

  describe '#create_risk_alert' do
    it 'creates alert with appropriate level' do
      risk = { id: 1, title: 'Test Risk', severity: 'high', impact: 'major' }
      
      alert = controller.send(:create_risk_alert, risk, :warning)
      
      expect(alert[:level]).to eq(:warning)
      expect(alert[:title]).to include('Attention requise')
      expect(alert[:type]).to eq('risk_alert')
    end
    
    it 'includes UUID for alert' do
      risk = { id: 1, title: 'Test Risk' }
      alert = controller.send(:create_risk_alert, risk)
      
      expect(alert[:id]).to be_present
      expect(alert[:id]).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
    end
  end

  describe '#create_overdue_alert' do
    it 'counts overdue actions correctly' do
      risk = {
        id: 1,
        title: 'Risk with overdue actions',
        mitigation_actions: [
          { id: 1, due_date: 2.days.ago, status: 'in_progress' },
          { id: 2, due_date: 1.week.ago, status: 'planned' },
          { id: 3, due_date: 1.day.from_now, status: 'planned' }
        ]
      }
      
      alert = controller.send(:create_overdue_alert, risk)
      
      expect(alert[:overdue_count]).to eq(2)
      expect(alert[:oldest_overdue]).to eq(1.week.ago.to_date)
    end
  end

  describe '#create_emerging_alert' do
    it 'creates emerging risk alert with indicators' do
      emerging_risk = {
        title: 'Budget Risk',
        indicators: ['Budget at 95%', 'Cost overruns detected'],
        recommended_action: 'Review budget allocation'
      }
      
      alert = controller.send(:create_emerging_alert, emerging_risk)
      
      expect(alert[:type]).to eq('emerging_risk')
      expect(alert[:level]).to eq(:info)
      expect(alert[:indicators]).to eq(emerging_risk[:indicators])
      expect(alert[:recommended_action]).to eq(emerging_risk[:recommended_action])
    end
  end

  describe '#suggest_alert_actions' do
    it 'suggests immediate actions for critical risks' do
      risk = { id: 1, title: 'Critical Risk' }
      actions = controller.send(:suggest_alert_actions, risk, :critical)
      
      expect(actions).to be_an(Array)
      expect(actions.any? { |a| a[:urgency] == 'immediate' }).to be true
      expect(actions.map { |a| a[:action] }).to include('notify_management')
    end
    
    it 'suggests review for warning level' do
      risk = { id: 1, title: 'Warning Risk' }
      actions = controller.send(:suggest_alert_actions, risk, :warning)
      
      expect(actions.any? { |a| a[:action] == 'schedule_review' }).to be true
    end
    
    it 'always includes view details action' do
      risk = { id: 1, title: 'Any Risk' }
      
      [:critical, :warning, :info].each do |level|
        actions = controller.send(:suggest_alert_actions, risk, level)
        expect(actions.any? { |a| a[:action] == 'view_risk_details' }).to be true
      end
    end
  end

  describe '#has_overdue_actions?' do
    it 'returns true when risk has overdue actions' do
      risk = {
        mitigation_actions: [
          { status: 'in_progress', due_date: 1.day.ago },
          { status: 'planned', due_date: 1.week.from_now }
        ]
      }
      
      expect(controller.send(:has_overdue_actions?, risk)).to be true
    end
    
    it 'returns false when all actions are completed' do
      risk = {
        mitigation_actions: [
          { status: 'completed', due_date: 1.day.ago },
          { status: 'completed', due_date: 1.week.ago }
        ]
      }
      
      expect(controller.send(:has_overdue_actions?, risk)).to be false
    end
    
    it 'returns false when no actions exist' do
      risk = {}
      expect(controller.send(:has_overdue_actions?, risk)).to be false
    end
  end

  describe '#detect_emerging_risks_for_project' do
    before do
      controller.project = project
    end

    it 'detects schedule risks when phases are delayed' do
      allow(project).to receive_message_chain(:phases, :any?).and_return(true)
      
      get :test_emerging_risks
      risks = JSON.parse(response.body)
      
      schedule_risk = risks.find { |r| r['type'] == 'schedule_risk' }
      expect(schedule_risk).to be_present
    end
    
    it 'detects budget risks when budget usage is high' do
      allow(project).to receive(:budget_usage_percentage).and_return(95)
      allow(project).to receive(:completion_percentage).and_return(70)
      
      get :test_emerging_risks
      risks = JSON.parse(response.body)
      
      budget_risk = risks.find { |r| r['type'] == 'budget_risk' }
      expect(budget_risk).to be_present
    end
  end

  describe '#determine_alert_recipients' do
    before do
      controller.project = project
    end

    it 'includes project manager for critical alerts' do
      manager = create(:user, organization: organization)
      project.update(project_manager: manager)
      
      alert = { level: :critical, risk_id: 1 }
      recipients = controller.send(:determine_alert_recipients, alert)
      
      expect(recipients).to include(manager)
    end
    
    it 'includes stakeholders with director role for critical alerts' do
      director = create(:user, organization: organization)
      create(:immo_promo_stakeholder, project: project, user: director, role: 'director')
      
      alert = { level: :critical }
      recipients = controller.send(:determine_alert_recipients, alert)
      
      expect(recipients).to include(director)
    end
  end

  describe '#should_send_notification?' do
    it 'always sends critical alerts' do
      alert = { level: :critical }
      expect(controller.send(:should_send_notification?, alert)).to be true
    end
    
    it 'checks recency for warning alerts' do
      alert = { level: :warning }
      allow(controller).to receive(:alert_recently_sent?).and_return(false)
      
      expect(controller.send(:should_send_notification?, alert)).to be true
    end
    
    it 'checks recency for info alerts' do
      alert = { level: :info }
      allow(controller).to receive(:alert_recently_sent?).with(alert, 3.days).and_return(true)
      
      expect(controller.send(:should_send_notification?, alert)).to be false
    end
  end
end