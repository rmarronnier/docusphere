require 'rails_helper'

RSpec.describe Immo::Promo::StakeholderNotificationService do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:current_user) { create(:user) }
  let(:service) { described_class.new(project, current_user) }
  
  describe '#notify_stakeholders' do
    let!(:active_stakeholder) do
      create(:immo_promo_stakeholder,
        project: project,
        email: 'active@example.com',
        is_active: true
      )
    end
    
    let!(:inactive_stakeholder) do
      create(:immo_promo_stakeholder,
        project: project,
        email: 'inactive@example.com',
        is_active: false
      )
    end
    
    context 'when notifying all stakeholders' do
      it 'only notifies active stakeholders' do
        expect {
          service.notify_stakeholders('Project update', type: :update)
        }.to change(Notification, :count).by(1)
      end
      
      it 'creates notification with correct attributes' do
        service.notify_stakeholders('Important message', type: :alert)
        
        notification = Notification.last
        expect(notification.message).to eq('Important message')
        expect(notification.notification_type).to eq('system_announcement')
        expect(notification.user).to eq(current_user)
      end
      
      it 'sends emails to stakeholders' do
        expect(Immo::Promo::StakeholderMailer).to receive(:notification_email).with(active_stakeholder, anything).and_return(double(deliver_later: true))
        service.notify_stakeholders('Project update', type: :update)
      end
    end
    
    context 'when filtering by stakeholder type' do
      let!(:architect) do
        create(:immo_promo_stakeholder,
          project: project,
          stakeholder_type: 'architect',
          is_active: true
        )
      end
      
      let!(:contractor) do
        create(:immo_promo_stakeholder,
          project: project,
          stakeholder_type: 'contractor',
          is_active: true
        )
      end
      
      it 'only notifies specified types' do
        expect {
          service.notify_stakeholders('Architect meeting', 
            type: :meeting,
            stakeholder_types: ['architect']
          )
        }.to change(Notification, :count).by(1)
      end
    end
    
    context 'when filtering by roles' do
      let!(:primary_stakeholder) do
        create(:immo_promo_stakeholder,
          project: project,
          is_primary: true,
          is_active: true
        )
      end
      
      let!(:secondary_stakeholder) do
        create(:immo_promo_stakeholder,
          project: project,
          is_primary: false,
          is_active: true
        )
      end
      
      it 'only notifies stakeholders with specified roles' do
        expect {
          service.notify_stakeholders('Critical update',
            type: :alert,
            roles: ['primary']
          )
        }.to change(Notification, :count).by(1)
      end
    end
  end
  
  describe '#schedule_coordination_meeting' do
    let!(:stakeholders) do
      create_list(:immo_promo_stakeholder, 3, project: project, is_active: true)
    end
    
    let(:meeting_details) do
      {
        title: 'Project Coordination Meeting',
        date: 1.week.from_now,
        location: 'Conference Room A',
        agenda: 'Review project progress'
      }
    end
    
    it 'creates meeting notification' do
      expect {
        service.schedule_coordination_meeting(stakeholders.map(&:id), meeting_details)
      }.to change(Notification, :count).by(1)
    end
    
    it 'sends invitations to specified stakeholders' do
      stakeholders.each do |stakeholder|
        expect(Immo::Promo::StakeholderMailer).to receive(:notification_email).with(stakeholder, anything).and_return(double(deliver_later: true))
      end
      service.schedule_coordination_meeting(stakeholders.map(&:id), meeting_details)
    end
    
    it 'includes meeting details in notification' do
      service.schedule_coordination_meeting(stakeholders.map(&:id), meeting_details)
      
      notification = Notification.last
      expect(notification.title).to include('Project Coordination Meeting')
      expect(notification.notification_type).to eq('system_announcement')
    end
  end
  
  describe '#send_status_update' do
    let!(:stakeholders) do
      create_list(:immo_promo_stakeholder, 2, project: project, is_active: true)
    end
    
    let(:status_info) do
      {
        phase: 'Construction',
        progress: 45,
        milestones_completed: 3,
        next_milestone: 'Foundation Complete'
      }
    end
    
    it 'sends status update to all active stakeholders' do
      expect {
        service.send_status_update(status_info)
      }.to change(Notification, :count).by(2) # 2 active stakeholders
    end
    
    it 'formats status message correctly' do
      service.send_status_update(status_info)
      
      notification = Notification.last
      expect(notification.message).to include('Construction')
      expect(notification.message).to include('45%')
    end
  end
  
  describe '#send_deadline_reminder' do
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project, is_active: true) }
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:task) do
      create(:immo_promo_task,
        phase: phase,
        stakeholder: stakeholder,
        name: 'Submit drawings',
        end_date: 3.days.from_now
      )
    end
    
    it 'sends deadline reminder' do
      expect {
        service.send_deadline_reminder(task, stakeholder)
      }.to change(Notification, :count).by(1)
    end
    
    it 'includes task details in reminder' do
      service.send_deadline_reminder(task, stakeholder)
      
      notification = Notification.last
      expect(notification.message).to include('Submit drawings')
      expect(notification.message).to include('3 jours')
      expect(notification.notification_type).to eq('system_announcement')
    end
  end
  
  describe '#send_coordination_alerts' do
    context 'with upcoming tasks' do
      let!(:stakeholder) { create(:immo_promo_stakeholder, project: project, is_active: true) }
      let!(:phase) { create(:immo_promo_phase, project: project) }
      let!(:task) do
        create(:immo_promo_task,
          phase: phase,
          stakeholder: stakeholder,
          start_date: 2.days.from_now,
          status: 'pending'
        )
      end
      
      it 'sends alerts for upcoming tasks' do
        expect {
          service.send_coordination_alerts
        }.to change(Notification, :count).by_at_least(1)
      end
    end
    
    context 'with overdue tasks' do
      let!(:stakeholder) { create(:immo_promo_stakeholder, project: project, is_active: true) }
      let!(:phase) { create(:immo_promo_phase, project: project) }
      let!(:overdue_task) do
        create(:immo_promo_task,
          phase: phase,
          stakeholder: stakeholder,
          start_date: 2.weeks.ago,
          end_date: 1.week.ago,
          status: 'in_progress'
        )
      end
      
      it 'sends alerts for overdue tasks' do
        expect {
          service.send_coordination_alerts
        }.to change(Notification, :count).by_at_least(1)
      end
    end
  end
  
  describe 'private notification helpers' do
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project, is_active: true) }
    
    it 'creates notifications in database' do
      expect {
        service.notify_stakeholders('Test message', type: :info)
      }.to change(Notification, :count).by(1)
    end
    
    it 'queues email delivery' do
      expect(Immo::Promo::StakeholderMailer).to receive(:notification_email).with(stakeholder, anything).and_return(double(deliver_later: true))
      service.notify_stakeholders('Test message', type: :info)
    end
    
    it 'sets correct notification attributes' do
      service.notify_stakeholders('Custom message', type: :alert, metadata: { priority: 'high' })
      
      notification = Notification.last
      expect(notification.message).to eq('Custom message')
      expect(notification.notification_type).to eq('system_announcement')
      expect(notification.formatted_data['priority']).to eq('high')
    end
  end
end