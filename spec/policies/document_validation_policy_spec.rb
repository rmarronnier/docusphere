require 'rails_helper'

RSpec.describe DocumentValidationPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:validator) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  let(:validation_request) { create(:validation_request, validatable: document, requester: user) }
  let(:document_validation) { create(:document_validation, validation_request: validation_request, validator: validator, status: 'pending') }
  
  subject { described_class }

  permissions :index? do
    it 'grants access to authenticated user' do
      expect(subject).to permit(user, :document_validation)
    end

    it 'denies access to nil user' do
      expect(subject).not_to permit(nil, :document_validation)
    end
  end

  permissions :approve? do
    context 'when user is the validator and validation is pending' do
      it 'grants access' do
        expect(subject).to permit(validator, document_validation)
      end
    end

    context 'when user is not the validator' do
      it 'denies access' do
        expect(subject).not_to permit(other_user, document_validation)
      end
    end

    context 'when validation is not pending' do
      before do
        document_validation.update!(status: 'approved', comment: 'Test comment')
      end

      it 'denies access even to validator' do
        expect(subject).not_to permit(validator, document_validation)
      end
    end

    context 'when user is nil' do
      it 'denies access' do
        expect(subject).not_to permit(nil, document_validation)
      end
    end
  end

  permissions :reject? do
    context 'when user is the validator and validation is pending' do
      it 'grants access' do
        expect(subject).to permit(validator, document_validation)
      end
    end

    context 'when user is not the validator' do
      it 'denies access' do
        expect(subject).not_to permit(other_user, document_validation)
      end
    end

    context 'when validation is not pending' do
      before do
        document_validation.update!(status: 'rejected', comment: 'Test comment')
      end

      it 'denies access even to validator' do
        expect(subject).not_to permit(validator, document_validation)
      end
    end

    context 'when user is nil' do
      it 'denies access' do
        expect(subject).not_to permit(nil, document_validation)
      end
    end
  end

  describe 'Scope' do
    let!(:user_validation) { create(:document_validation, validation_request: validation_request, validator: user) }
    let!(:other_validation) { create(:document_validation, validation_request: validation_request, validator: validator) }

    it 'returns only validations for the user' do
      scope = DocumentValidationPolicy::Scope.new(user, DocumentValidation).resolve
      expect(scope).to include(user_validation)
      expect(scope).not_to include(other_validation)
    end

    it 'returns empty scope for nil user' do
      scope = DocumentValidationPolicy::Scope.new(nil, DocumentValidation).resolve
      expect(scope).to be_empty
    end
  end

  describe '#permitted_attributes' do
    let(:policy) { described_class.new(user, document_validation) }
    
    it "returns the correct permitted attributes" do
      expect(policy.permitted_attributes).to contain_exactly(:status, :comment, validation_data: {})
    end
    
    it "returns the same attributes for all users" do
      other_policy = described_class.new(other_user, document_validation)
      
      expect(other_policy.permitted_attributes).to eq(policy.permitted_attributes)
    end
  end
end