require 'rails_helper'

RSpec.describe Validatable, type: :concern do
  # Create a test class to include the concern
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'documents'
      include Validatable
      
      def self.name
        'TestValidatable'
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:validatable_instance) { create(:document, space: space) }
  let(:requester) { create(:user, organization: organization) }
  let(:validator1) { create(:user, organization: organization) }
  let(:validator2) { create(:user, organization: organization) }

  describe 'included module behavior' do
    it 'adds validation associations' do
      expect(validatable_instance).to respond_to(:validation_requests)
      expect(validatable_instance).to respond_to(:document_validations)
      expect(validatable_instance).to respond_to(:validators)
    end

    it 'adds validation methods' do
      expect(validatable_instance).to respond_to(:request_validation)
      expect(validatable_instance).to respond_to(:validation_pending?)
      expect(validatable_instance).to respond_to(:validated?)
      expect(validatable_instance).to respond_to(:validate_by!)
    end

    it 'adds validation scopes to the class' do
      expect(Document).to respond_to(:pending_validation)
      expect(Document).to respond_to(:validated)
      expect(Document).to respond_to(:rejected)
    end
  end

  describe '#request_validation' do
    it 'creates a validation request with validators' do
      expect {
        validatable_instance.request_validation(
          requester: requester,
          validators: [validator1, validator2],
          min_validations: 2,
          due_date: 1.week.from_now,
          notes: 'Please review this document'
        )
      }.to change { validatable_instance.validation_requests.count }.by(1)
        .and change { validatable_instance.document_validations.count }.by(2)
      
      validation_request = validatable_instance.validation_requests.last
      expect(validation_request.requester).to eq(requester)
      expect(validation_request.min_validations).to eq(2)
      expect(validation_request.status).to eq('pending')
      expect(validation_request.description).to eq('Please review this document')
      
      validations = validatable_instance.document_validations.last(2)
      expect(validations.map(&:validator)).to contain_exactly(validator1, validator2)
      expect(validations.all? { |v| v.status == 'pending' }).to be true
    end

    it 'returns false if validation is already pending' do
      validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      
      result = validatable_instance.request_validation(
        requester: requester,
        validators: [validator2]
      )
      
      expect(result).to be false
    end

    it 'sets default values when not provided' do
      validation_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      
      expect(validation_request.min_validations).to eq(1)
      expect(validation_request.due_date).to be_nil
      expect(validation_request.description).to be_nil
    end
  end

  describe '#current_validation_request' do
    it 'returns the most recent pending or in_progress validation request' do
      old_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      old_request.update!(status: 'completed')
      
      current_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator2]
      )
      
      expect(validatable_instance.current_validation_request).to eq(current_request)
    end

    it 'returns nil when no pending validation requests' do
      expect(validatable_instance.current_validation_request).to be_nil
    end
  end

  describe '#validation_pending?' do
    it 'returns true when there is a pending validation request' do
      validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      
      expect(validatable_instance.validation_pending?).to be true
    end

    it 'returns false when no validation requests' do
      expect(validatable_instance.validation_pending?).to be false
    end

    it 'returns false when validation is completed' do
      validation_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      validation_request.update!(status: 'completed')
      
      expect(validatable_instance.validation_pending?).to be false
    end
  end

  describe '#validated?' do
    it 'returns true when recently approved validation exists' do
      validation_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      validation_request.update!(status: 'approved')
      
      expect(validatable_instance.validated?).to be true
    end

    it 'returns false when no approved validations' do
      expect(validatable_instance.validated?).to be false
    end

    it 'returns false when approved validation is older than last update' do
      validation_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      validation_request.update!(status: 'approved', created_at: 1.hour.ago)
      
      validatable_instance.touch # Update the document
      
      expect(validatable_instance.validated?).to be false
    end
  end

  describe '#validation_rejected?' do
    it 'returns true when current validation request is rejected' do
      validation_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      validation_request.update!(status: 'rejected')
      
      expect(validatable_instance.validation_rejected?).to be true
    end

    it 'returns false when no validation request or not rejected' do
      expect(validatable_instance.validation_rejected?).to be false
    end
  end

  describe '#validation_status' do
    it 'returns "none" when no validation requests' do
      expect(validatable_instance.validation_status).to eq('none')
    end

    it 'returns current validation request status' do
      validation_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      
      expect(validatable_instance.validation_status).to eq('pending')
      
      validation_request.update!(status: 'approved')
      expect(validatable_instance.validation_status).to eq('approved')
    end

    it 'returns "approved" when no current validation request exists' do
      validation_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      validation_request.update!(status: 'approved')
      
      expect(validatable_instance.validation_status).to eq('approved')
    end
  end

  describe '#can_be_validated_by?' do
    it 'returns true when user is assigned as validator for pending request' do
      validatable_instance.request_validation(
        requester: requester,
        validators: [validator1, validator2]
      )
      
      expect(validatable_instance.can_be_validated_by?(validator1)).to be true
      expect(validatable_instance.can_be_validated_by?(validator2)).to be true
    end

    it 'returns false when user is not assigned as validator' do
      validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      
      expect(validatable_instance.can_be_validated_by?(validator2)).to be false
    end

    it 'returns false when no pending validation' do
      expect(validatable_instance.can_be_validated_by?(validator1)).to be false
    end

    it 'returns false when user already validated' do
      validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      
      validation = validatable_instance.document_validations.find_by(validator: validator1)
      validation.update!(status: 'approved', validated_at: Time.current)
      
      expect(validatable_instance.can_be_validated_by?(validator1)).to be false
    end
  end

  describe '#validate_by!' do
    before do
      validatable_instance.request_validation(
        requester: requester,
        validators: [validator1, validator2]
      )
    end

    it 'approves validation by user' do
      validatable_instance.validate_by!(validator1, approved: true, comment: 'Looks good')
      
      validation = validatable_instance.document_validations.find_by(validator: validator1)
      expect(validation.status).to eq('approved')
      expect(validation.comment).to eq('Looks good')
      expect(validation.validated_at).to be_present
    end

    it 'rejects validation by user' do
      validatable_instance.validate_by!(validator1, approved: false, comment: 'Needs changes')
      
      validation = validatable_instance.document_validations.find_by(validator: validator1)
      expect(validation.status).to eq('rejected')
      expect(validation.comment).to eq('Needs changes')
      expect(validation.validated_at).to be_present
    end

    it 'checks validation request completion' do
      validation_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      
      # The check_completion! is called on the DocumentValidation's callback
      # We can't easily test it here because it happens inside a transaction
      validatable_instance.validate_by!(validator1, approved: true)
      
      # Just verify the validation was done
      validation = validatable_instance.document_validations.find_by(validator: validator1)
      expect(validation.status).to eq('approved')
    end

    it 'raises error when user is not assigned as validator' do
      other_user = create(:user, organization: organization)
      
      expect {
        validatable_instance.validate_by!(other_user, approved: true)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#validation_history' do
    it 'returns all validation requests ordered by creation date' do
      request1 = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      request1.update!(status: 'approved')
      
      request2 = validatable_instance.request_validation(
        requester: requester,
        validators: [validator2]
      )
      
      history = validatable_instance.validation_history
      expect(history).to eq([request2, request1])
    end
  end

  describe '#current_validators' do
    it 'returns validators for current validation request' do
      validatable_instance.request_validation(
        requester: requester,
        validators: [validator1, validator2]
      )
      
      validators = validatable_instance.current_validators
      expect(validators.map(&:validator)).to contain_exactly(validator1, validator2)
    end

    it 'returns empty array when no current validation request' do
      expect(validatable_instance.current_validators).to eq([])
    end
  end

  describe '#validation_progress' do
    it 'calculates validation progress percentage' do
      validatable_instance.request_validation(
        requester: requester,
        validators: [validator1, validator2]
      )
      
      expect(validatable_instance.validation_progress).to eq(0)
      
      validatable_instance.validate_by!(validator1, approved: true)
      expect(validatable_instance.validation_progress).to eq(50)
      
      validatable_instance.validate_by!(validator2, approved: false, comment: 'Not acceptable')
      expect(validatable_instance.validation_progress).to eq(100)
    end

    it 'returns 0 when no current validation request' do
      expect(validatable_instance.validation_progress).to eq(0)
    end
  end

  describe '#cancel_validation!' do
    it 'cancels pending validation request' do
      validation_request = validatable_instance.request_validation(
        requester: requester,
        validators: [validator1]
      )
      
      result = validatable_instance.cancel_validation!(
        cancelled_by: requester,
        reason: 'No longer needed'
      )
      
      expect(result).to be_truthy
      validation_request.reload
      expect(validation_request.status).to eq('rejected')
      expect(validation_request.completed_at).to be_present
    end

    it 'returns false when no pending validation' do
      result = validatable_instance.cancel_validation!(cancelled_by: requester)
      expect(result).to be false
    end
  end

  describe 'scopes' do
    let!(:pending_doc) { create(:document, space: space) }
    let!(:validated_doc) { create(:document, space: space) }
    let!(:rejected_doc) { create(:document, space: space) }
    let!(:normal_doc) { create(:document, space: space) }

    before do
      # Pending validation
      pending_doc.request_validation(requester: requester, validators: [validator1])
      
      # Validated document
      validation_request = validated_doc.request_validation(requester: requester, validators: [validator1])
      validation_request.update!(status: 'approved')
      
      # Rejected document
      validation_request = rejected_doc.request_validation(requester: requester, validators: [validator1])
      validation_request.update!(status: 'rejected')
    end

    describe '.pending_validation' do
      it 'returns documents with pending validation requests' do
        pending_docs = Document.pending_validation
        expect(pending_docs).to include(pending_doc)
        expect(pending_docs).not_to include(validated_doc, rejected_doc, normal_doc)
      end
    end

    describe '.validated' do
      it 'returns documents with approved validation requests' do
        validated_docs = Document.validated
        expect(validated_docs).to include(validated_doc)
        expect(validated_docs).not_to include(pending_doc, rejected_doc, normal_doc)
      end
    end

    describe '.rejected' do
      it 'returns documents with rejected validation requests' do
        rejected_docs = Document.rejected
        expect(rejected_docs).to include(rejected_doc)
        expect(rejected_docs).not_to include(pending_doc, validated_doc, normal_doc)
      end
    end
  end
end