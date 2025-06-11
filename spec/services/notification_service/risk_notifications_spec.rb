require 'rails_helper'

RSpec.describe NotificationService::RiskNotifications do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:risk) { create(:immo_promo_risk, project: project) }
  let(:service) { NotificationService.new }
  
  describe '#notify_risk_identified' do
    it 'creates risk alert notification' do
      service.notify_risk_identified(risk)
      
      notification = Notification.last
      expect(notification.title).to include('New Risk Identified')
      expect(notification.message).to include(risk.title)
      expect(notification.priority).to eq(risk.priority)
    end
    
    it 'notifies risk management team' do
      risk_managers = create_list(:user, 2, organization: organization)
      allow(service).to receive(:risk_management_team).and_return(risk_managers)
      
      expect {
        service.notify_risk_identified(risk)
      }.to change(Notification, :count).by(2)
    end
  end
  
  describe '#notify_risk_escalated' do
    it 'creates urgent notification for high severity risks' do
      risk.update!(severity: 'critical', probability: 'high')
      
      service.notify_risk_escalated(risk)
      
      notification = Notification.last
      expect(notification.priority).to eq('urgent')
      expect(notification.requires_action).to be true
    end
  end
  
  describe '#notify_mitigation_required' do
    it 'assigns mitigation action to responsible parties' do
      responsible_user = create(:user, organization: organization)
      deadline = 5.days.from_now
      
      service.notify_mitigation_required(risk, responsible_user, deadline)
      
      notification = Notification.last
      expect(notification.user).to eq(responsible_user)
      expect(notification.action_url).to include("risks/#{risk.id}/mitigate")
      expect(notification.metadata['deadline']).to eq(deadline.to_s)
    end
  end
  
  describe '#notify_risk_status_update' do
    it 'notifies about risk resolution' do
      risk.update!(status: 'mitigated')
      
      service.notify_risk_status_update(risk, 'active', 'mitigated')
      
      notification = Notification.last
      expect(notification.title).to include('Risk Mitigated')
      expect(notification.priority).to eq('low')
    end
  end
  
  describe '#notify_risk_review_needed' do
    it 'creates periodic review reminders' do
      risks_for_review = create_list(:immo_promo_risk, 3, project: project)
      
      service.notify_risk_review_needed(project, risks_for_review)
      
      notification = Notification.last
      expect(notification.title).to include('Risk Review Required')
      expect(notification.message).to include('3 risks')
    end
  end
end