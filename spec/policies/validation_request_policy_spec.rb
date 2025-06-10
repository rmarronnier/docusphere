require 'rails_helper'

RSpec.describe ValidationRequestPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let(:validator) { create(:user, organization: organization) }
  let(:admin) { create(:user, organization: organization, role: 'admin') }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  let(:validation_request) { create(:validation_request, document: document, requester: user) }
  
  subject { described_class }

  permissions :show? do
    context 'when user is the requester' do
      it 'grants access' do
        expect(subject).to permit(user, validation_request)
      end
    end

    context 'when user is a validator' do
      before do
        create(:document_validation, validation_request: validation_request, validator: validator)
      end

      it 'grants access to validator' do
        expect(subject).to permit(validator, validation_request)
      end

      it 'denies access to non-validator' do
        expect(subject).not_to permit(other_user, validation_request)
      end
    end

    context 'when user is admin' do
      it 'grants access' do
        expect(subject).to permit(admin, validation_request)
      end
    end

    context 'when user is nil' do
      it 'denies access' do
        expect(subject).not_to permit(nil, validation_request)
      end
    end
  end

  permissions :create? do
    context 'when user can request validation on document' do
      before do
        allow(document).to receive(:can_request_validation?).with(user).and_return(true)
      end

      it 'grants access' do
        new_request = ValidationRequest.new(document: document)
        expect(subject).to permit(user, new_request)
      end
    end

    context 'when user cannot request validation on document' do
      before do
        allow(document).to receive(:can_request_validation?).with(user).and_return(false)
      end

      it 'denies access' do
        new_request = ValidationRequest.new(document: document)
        expect(subject).not_to permit(user, new_request)
      end
    end

    context 'when user is nil' do
      it 'denies access' do
        new_request = ValidationRequest.new(document: document)
        expect(subject).not_to permit(nil, new_request)
      end
    end
  end

  permissions :my_requests? do
    it 'grants access to authenticated user' do
      expect(subject).to permit(user, :validation_request)
    end

    it 'denies access to nil user' do
      expect(subject).not_to permit(nil, :validation_request)
    end
  end

  describe 'Scope' do
    let!(:user_request) { create(:validation_request, validatable: document, requester: user) }
    let!(:other_request) { create(:validation_request, validatable: document, requester: other_user) }

    it 'returns only requests for the user' do
      scope = ValidationRequestPolicy::Scope.new(user, ValidationRequest).resolve
      expect(scope).to include(user_request)
      expect(scope).not_to include(other_request)
    end

    it 'returns empty scope for nil user' do
      scope = ValidationRequestPolicy::Scope.new(nil, ValidationRequest).resolve
      expect(scope).to be_empty
    end
  end

  describe '#permitted_attributes' do
    let(:policy) { described_class.new(requester, validation_request) }
    
    it "returns the correct permitted attributes" do
      expect(policy.permitted_attributes).to contain_exactly(:min_validations, :description, :due_date)
    end
    
    it "returns the same attributes for all users" do
      validator_policy = described_class.new(validator, validation_request)
      admin_policy = described_class.new(admin_user, validation_request)
      
      expect(validator_policy.permitted_attributes).to eq(policy.permitted_attributes)
      expect(admin_policy.permitted_attributes).to eq(policy.permitted_attributes)
    end
  end
end