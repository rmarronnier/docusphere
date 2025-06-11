require 'rails_helper'

RSpec.describe NotificationService::ProjectNotifications do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { NotificationService.new }
  
  describe '#notify_project_created' do
    it 'notifies all project stakeholders' do
      stakeholders = create_list(:user, 3, organization: organization)
      allow(service).to receive(:project_stakeholders).and_return(stakeholders)
      
      expect {
        service.notify_project_created(project)
      }.to change(Notification, :count).by(3)
    end
    
    it 'includes project details in notification' do
      service.notify_project_created(project)
      
      notification = Notification.last
      expect(notification.title).to include('New Project Created')
      expect(notification.message).to include(project.name)
      expect(notification.notification_type).to eq('project_announcement')
    end
  end
  
  describe '#notify_phase_started' do
    let(:phase) { create(:immo_promo_phase, project: project) }
    
    it 'notifies phase participants' do
      service.notify_phase_started(phase)
      
      notification = Notification.last
      expect(notification.title).to include('Phase Started')
      expect(notification.message).to include(phase.name)
      expect(notification.metadata['phase_id']).to eq(phase.id)
    end
  end
  
  describe '#notify_milestone_reached' do
    let(:milestone_data) do
      {
        name: 'Foundation Complete',
        achieved_date: Date.current,
        impact: 'Project can proceed to next phase'
      }
    end
    
    it 'creates celebration notification' do
      service.notify_milestone_reached(project, milestone_data)
      
      notification = Notification.last
      expect(notification.title).to include('Milestone Achieved')
      expect(notification.priority).to eq('low')
      expect(notification.notification_type).to eq('project_success')
    end
  end
  
  describe '#notify_project_delayed' do
    let(:delay_info) do
      {
        days_delayed: 15,
        reason: 'Weather conditions',
        new_end_date: 2.weeks.from_now
      }
    end
    
    it 'creates high priority delay notification' do
      service.notify_project_delayed(project, delay_info)
      
      notification = Notification.last
      expect(notification.title).to include('Project Delayed')
      expect(notification.message).to include('15 days')
      expect(notification.priority).to eq('high')
    end
  end
  
  describe '#notify_project_status_change' do
    it 'notifies about status transitions' do
      old_status = 'planning'
      new_status = 'in_progress'
      
      service.notify_project_status_change(project, old_status, new_status)
      
      notification = Notification.last
      expect(notification.message).to include('planning → in_progress')
    end
  end
end