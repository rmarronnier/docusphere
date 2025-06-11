require 'rails_helper'

RSpec.describe NotificationService::StakeholderNotifications do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
  let(:service) { NotificationService.new }
  
  describe '#notify_stakeholder_added' do
    it 'notifies project team about new stakeholder' do
      service.notify_stakeholder_added(stakeholder)
      
      notification = Notification.last
      expect(notification.title).to include('New Stakeholder Added')
      expect(notification.message).to include(stakeholder.name)
      expect(notification.message).to include(stakeholder.stakeholder_type)
    end
  end
  
  describe '#notify_task_assigned' do
    let(:task) { create(:immo_promo_task, stakeholder: stakeholder) }
    
    it 'notifies stakeholder of new task assignment' do
      contact_user = create(:user, email: stakeholder.email, organization: organization)
      
      service.notify_task_assigned(task)
      
      notification = contact_user.notifications.last
      expect(notification.title).to include('New Task Assigned')
      expect(notification.requires_action).to be true
      expect(notification.action_url).to include("tasks/#{task.id}")
    end
  end
  
  describe '#notify_qualification_expiring' do
    let(:certification) { create(:immo_promo_certification, stakeholder: stakeholder, expiry_date: 30.days.from_now) }
    
    it 'notifies about expiring qualifications' do
      service.notify_qualification_expiring(stakeholder, certification)
      
      notification = Notification.last
      expect(notification.title).to include('Qualification Expiring')
      expect(notification.message).to include(certification.name)
      expect(notification.message).to include('30 days')
    end
  end
  
  describe '#notify_performance_issue' do
    let(:performance_data) do
      {
        issue_type: 'delays',
        affected_tasks: 3,
        average_delay: 5
      }
    end
    
    it 'creates performance alert' do
      service.notify_performance_issue(stakeholder, performance_data)
      
      notification = Notification.last
      expect(notification.title).to include('Performance Issue')
      expect(notification.priority).to eq('medium')
      expect(notification.metadata['issue_type']).to eq('delays')
    end
  end
  
  describe '#notify_contract_milestone' do
    let(:contract) { create(:immo_promo_contract, stakeholder: stakeholder) }
    let(:milestone) { 'First payment due' }
    
    it 'notifies about contract milestones' do
      service.notify_contract_milestone(contract, milestone)
      
      notification = Notification.last
      expect(notification.title).to include('Contract Milestone')
      expect(notification.message).to include(milestone)
    end
  end
end