require 'rails_helper'

RSpec.describe NotificationService::PermitNotifications do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:permit) { create(:immo_promo_permit, project: project) }
  let(:service) { NotificationService.new }
  
  describe '#notify_permit_submitted' do
    it 'creates notifications for permit submission' do
      stakeholders = create_list(:user, 3, organization: organization)
      allow(service).to receive(:permit_stakeholders).with(permit).and_return(stakeholders)
      
      expect {
        service.notify_permit_submitted(permit)
      }.to change(Notification, :count).by(3)
    end
    
    it 'includes permit details in notification' do
      service.notify_permit_submitted(permit)
      
      notification = Notification.last
      expect(notification.title).to include('Permit Submitted')
      expect(notification.message).to include(permit.permit_type)
      expect(notification.message).to include(permit.reference_number)
      expect(notification.notification_type).to eq('permit_update')
    end
    
    it 'attaches permit document reference' do
      service.notify_permit_submitted(permit)
      
      notification = Notification.last
      expect(notification.metadata).to include(
        'permit_id' => permit.id,
        'permit_type' => permit.permit_type,
        'project_id' => project.id
      )
    end
  end
  
  describe '#notify_permit_approved' do
    before { permit.update!(status: 'approved', approved_at: Time.current) }
    
    it 'creates celebration notification' do
      service.notify_permit_approved(permit)
      
      notification = Notification.last
      expect(notification.title).to include('Permit Approved!')
      expect(notification.priority).to eq('low')
      expect(notification.notification_type).to eq('permit_success')
    end
    
    it 'triggers next phase notifications if applicable' do
      allow(service).to receive(:has_dependent_permits?).with(permit).and_return(true)
      
      expect(service).to receive(:notify_next_permit_phase).with(permit)
      
      service.notify_permit_approved(permit)
    end
  end
  
  describe '#notify_permit_rejected' do
    let(:rejection_reason) { 'Missing environmental impact study' }
    
    before { permit.update!(status: 'rejected') }
    
    it 'creates high priority notification' do
      service.notify_permit_rejected(permit, rejection_reason)
      
      notification = Notification.last
      expect(notification.title).to include('Permit Rejected')
      expect(notification.message).to include(rejection_reason)
      expect(notification.priority).to eq('high')
      expect(notification.requires_action).to be true
    end
    
    it 'includes remediation guidance' do
      service.notify_permit_rejected(permit, rejection_reason)
      
      notification = Notification.last
      expect(notification.metadata['rejection_reason']).to eq(rejection_reason)
      expect(notification.metadata['next_steps']).to be_present
    end
  end
  
  describe '#notify_permit_expiring' do
    let(:days_until_expiry) { 30 }
    
    it 'creates warning notification' do
      service.notify_permit_expiring(permit, days_until_expiry)
      
      notification = Notification.last
      expect(notification.title).to include('Permit Expiring Soon')
      expect(notification.message).to include('30 days')
      expect(notification.priority).to eq('medium')
    end
    
    it 'increases priority as expiry approaches' do
      service.notify_permit_expiring(permit, 7)
      
      notification = Notification.last
      expect(notification.priority).to eq('high')
      expect(notification.requires_action).to be true
    end
    
    it 'suggests renewal action' do
      service.notify_permit_expiring(permit, days_until_expiry)
      
      notification = Notification.last
      expect(notification.action_url).to include("permits/#{permit.id}/renew")
      expect(notification.metadata['renewal_deadline']).to be_present
    end
  end
  
  describe '#notify_permit_conditions_added' do
    let(:conditions) do
      [
        { description: 'Noise restrictions during construction', deadline: 30.days.from_now },
        { description: 'Weekly progress reports required', deadline: nil }
      ]
    end
    
    it 'notifies about new permit conditions' do
      service.notify_permit_conditions_added(permit, conditions)
      
      notification = Notification.last
      expect(notification.title).to include('Permit Conditions Added')
      expect(notification.message).to include('2 new conditions')
    end
    
    it 'lists all conditions in metadata' do
      service.notify_permit_conditions_added(permit, conditions)
      
      notification = Notification.last
      expect(notification.metadata['conditions']).to be_an(Array)
      expect(notification.metadata['conditions'].size).to eq(2)
    end
  end
  
  describe '#notify_permit_deadline_approaching' do
    let(:deadline_type) { 'submission' }
    let(:deadline) { 5.days.from_now }
    
    it 'creates deadline reminder' do
      service.notify_permit_deadline_approaching(permit, deadline_type, deadline)
      
      notification = Notification.last
      expect(notification.title).to include('Permit Deadline')
      expect(notification.message).to include('submission')
      expect(notification.message).to include('5 days')
    end
    
    it 'sets escalating reminders' do
      service.notify_permit_deadline_approaching(permit, deadline_type, 2.days.from_now)
      
      notification = Notification.last
      expect(notification.priority).to eq('urgent')
      expect(notification.metadata['auto_escalate']).to be true
    end
  end
  
  describe '#notify_permit_document_required' do
    let(:required_documents) do
      [
        { type: 'Environmental Impact Study', deadline: 10.days.from_now },
        { type: 'Traffic Management Plan', deadline: 15.days.from_now }
      ]
    end
    
    it 'creates notification for missing documents' do
      service.notify_permit_document_required(permit, required_documents)
      
      notification = Notification.last
      expect(notification.title).to include('Documents Required')
      expect(notification.message).to include('2 documents')
      expect(notification.requires_action).to be true
    end
    
    it 'provides upload action' do
      service.notify_permit_document_required(permit, required_documents)
      
      notification = Notification.last
      expect(notification.action_url).to include("permits/#{permit.id}/documents")
      expect(notification.metadata['required_documents']).to eq(required_documents)
    end
  end
end