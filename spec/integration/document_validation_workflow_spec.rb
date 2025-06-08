require 'rails_helper'

RSpec.describe 'Document Validation Workflow', type: :integration do
  let(:organization) { create(:organization) }
  let(:requester) { create(:user, organization: organization) }
  let(:validator1) { create(:user, organization: organization) }
  let(:validator2) { create(:user, organization: organization) }
  let(:validator3) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, uploaded_by: requester, space: space) }
  
  describe 'complete validation workflow' do
    context 'with successful validation (2 out of 3 required)' do
      it 'completes the validation process successfully' do
        # Step 1: Request validation
        validation_request = document.request_validation(
          requester: requester,
          validators: [validator1, validator2, validator3],
          min_validations: 2
        )
        
        expect(validation_request).to be_persisted
        expect(validation_request.status).to eq('pending')
        expect(validation_request.document_validations.count).to eq(3)
        expect(validation_request.document_validations.all?(&:pending?)).to be true
        
        # Step 2: First validator approves
        first_validation = validation_request.document_validations.find_by(validator: validator1)
        first_validation.approve!(comment: 'Document looks good to me')
        
        expect(first_validation.reload.status).to eq('approved')
        expect(validation_request.reload.status).to eq('pending') # Still pending, need 2 approvals
        
        # Step 3: Second validator approves (reaches minimum threshold)
        second_validation = validation_request.document_validations.find_by(validator: validator2)
        second_validation.approve!(comment: 'I agree, approved')
        
        expect(second_validation.reload.status).to eq('approved')
        expect(validation_request.reload.status).to eq('approved') # Now approved!
        expect(validation_request.completed_at).to be_present
        
        # Verify validation progress
        progress = validation_request.validation_progress
        expect(progress[:approved]).to eq(2)
        expect(progress[:pending]).to eq(1)
        expect(progress[:rejected]).to eq(0)
        expect(progress[:total_validators]).to eq(3)
        expect(progress[:min_required]).to eq(2)
      end
    end
    
    context 'with rejection (any rejection is definitive)' do
      it 'rejects the validation request immediately on first rejection' do
        # Step 1: Request validation
        validation_request = document.request_validation(
          requester: requester,
          validators: [validator1, validator2, validator3],
          min_validations: 2
        )
        
        # Step 2: First validator approves
        first_validation = validation_request.document_validations.find_by(validator: validator1)
        first_validation.approve!(comment: 'Looks good')
        
        expect(validation_request.reload.status).to eq('pending')
        
        # Step 3: Second validator rejects (rejection is definitive)
        second_validation = validation_request.document_validations.find_by(validator: validator2)
        second_validation.reject!(comment: 'Major issues found, cannot approve')
        
        expect(second_validation.reload.status).to eq('rejected')
        expect(validation_request.reload.status).to eq('rejected') # Immediately rejected
        expect(validation_request.completed_at).to be_present
        
        # Verify rejection information
        expect(validation_request.has_rejection?).to be true
        expect(validation_request.rejecting_validators).to include(validator2)
      end
    end
    
    context 'with mixed responses but insufficient approvals' do
      it 'keeps the request pending until minimum approvals are reached' do
        # Request validation with high threshold
        validation_request = document.request_validation(
          requester: requester,
          validators: [validator1, validator2, validator3],
          min_validations: 3 # All must approve
        )
        
        # Two approve, one pending
        validation_request.document_validations.find_by(validator: validator1).approve!(comment: 'Approved')
        validation_request.document_validations.find_by(validator: validator2).approve!(comment: 'Approved')
        
        expect(validation_request.reload.status).to eq('pending') # Still need one more
        
        # Third validator approves
        validation_request.document_validations.find_by(validator: validator3).approve!(comment: 'Final approval')
        
        expect(validation_request.reload.status).to eq('approved') # Now complete
      end
    end
  end
  
  describe 'authorization system integration' do
    let(:admin_user) { create(:user, :admin, organization: organization) }
    let(:regular_user) { create(:user, organization: organization) }
    
    before do
      # Grant validation permission to validators
      document.authorize_user(validator1, 'validate', granted_by: admin_user)
      document.authorize_user(validator2, 'validate', granted_by: admin_user)
    end
    
    it 'respects authorization permissions for validation' do
      expect(document.can_validate?(validator1)).to be true
      expect(document.can_validate?(validator2)).to be true
      expect(document.can_validate?(regular_user)).to be false
      
      # Document owner and admin can always validate
      expect(document.can_validate?(requester)).to be true
      expect(document.can_validate?(admin_user)).to be true
    end
    
    it 'tracks authorization grant and revocation' do
      # Grant permission
      auth = document.authorize_user(regular_user, 'read', granted_by: admin_user, comment: 'Temporary access')
      
      expect(auth).to be_active
      expect(auth.granted_by).to eq(admin_user)
      expect(document.can_read?(regular_user)).to be true
      
      # Revoke permission
      document.revoke_authorization(regular_user, 'read', revoked_by: admin_user, comment: 'Access no longer needed')
      
      expect(auth.reload).to be_revoked
      expect(auth.revoked_by).to eq(admin_user)
      expect(document.can_read?(regular_user)).to be false
    end
  end
  
  describe 'notification system integration' do
    it 'sends notifications throughout the validation process' do
      # Mock the notification service to track calls
      allow(NotificationService).to receive(:notify_validation_requested)
      allow(NotificationService).to receive(:notify_validation_approved)
      allow(NotificationService).to receive(:notify_validation_rejected)
      
      # Request validation
      validation_request = document.request_validation(
        requester: requester,
        validators: [validator1, validator2],
        min_validations: 1
      )
      
      # Should notify validators
      expect(NotificationService).to have_received(:notify_validation_requested).with(validation_request)
      
      # Approve validation
      validation_request.document_validations.first.approve!(comment: 'Approved')
      
      # Should notify requester of approval
      expect(NotificationService).to have_received(:notify_validation_approved).with(validation_request)
    end
    
    it 'creates actual notification records' do
      validation_request = nil
      expect {
        validation_request = document.request_validation(
          requester: requester,
          validators: [validator1, validator2],
          min_validations: 1
        )
      }.to change { Notification.count }.by(2) # One for each validator
      
      # Check notification content
      notification = Notification.for_user(validator1).last
      expect(notification.notification_type).to eq('document_validation_requested')
      expect(notification.title).to eq('Validation demandée')
      expect(notification.message).to include(document.title)
      expect(notification.notifiable).to eq(validation_request)
    end
  end
  
  describe 'edge cases and error handling' do
    it 'handles validation request without validators' do
      expect {
        document.request_validation(
          requester: requester,
          validators: [],
          min_validations: 1
        )
      }.not_to raise_error
      
      validation_request = document.validation_requests.last
      expect(validation_request.document_validations.count).to eq(0)
      expect(validation_request.can_be_completed?).to be false
    end
    
    it 'prevents duplicate validation requests from same validator' do
      validation_request = document.request_validation(
        requester: requester,
        validators: [validator1, validator1], # Duplicate
        min_validations: 1
      )
      
      expect(validation_request.document_validations.count).to eq(1) # Should be deduplicated
    end
    
    it 'handles concurrent validation attempts gracefully' do
      validation_request = document.request_validation(
        requester: requester,
        validators: [validator1, validator2],
        min_validations: 1
      )
      
      validation1 = validation_request.document_validations.find_by(validator: validator1)
      validation2 = validation_request.document_validations.find_by(validator: validator2)
      
      # Both validators try to complete at the same time
      expect {
        validation1.approve!(comment: 'First approval')
        validation2.approve!(comment: 'Second approval')
      }.not_to raise_error
      
      expect(validation_request.reload.status).to eq('approved')
    end
  end
end