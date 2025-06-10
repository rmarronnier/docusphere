require 'rails_helper'

RSpec.describe DocumentValidation, type: :model do
  let(:document) { create(:document) }
  let(:validator) { create(:user) }
  let(:validation_request) { create(:validation_request, validatable: document) }
  
  describe 'validations' do
    it { should validate_presence_of(:status) }
    it 'validates status values are limited to enum' do
      expect { build(:document_validation, status: 'invalid') }.to raise_error(ArgumentError)
    end
    
    it 'requires comment for rejected validations' do
      validation = build(:document_validation, status: 'rejected', comment: nil)
      expect(validation).not_to be_valid
      expect(validation.errors[:comment]).to include("ne peut pas être vide")
    end
    
    it 'does not require comment for approved validations' do
      validation = build(:document_validation, status: 'approved', comment: nil)
      expect(validation).to be_valid
    end
    
    it 'validates uniqueness of validator per document and request' do
      create(:document_validation, 
        validatable: document, 
        validator: validator, 
        validation_request: validation_request
      )
      
      duplicate = build(:document_validation,
        validatable: document,
        validator: validator, 
        validation_request: validation_request
      )
      
      expect(duplicate).not_to be_valid
    end
  end
  
  describe 'associations' do
    it { should belong_to(:validatable) }
    it { should belong_to(:validator) }
    it { should belong_to(:validation_request) }
  end
  
  describe '#approve!' do
    let(:validation) { create(:document_validation, status: 'pending') }
    
    it 'sets status to approved and sets validated_at' do
      validation.approve!(comment: 'Looks good')
      
      expect(validation.reload.status).to eq('approved')
      expect(validation.validated_at).to be_present
      expect(validation.comment).to eq('Looks good')
    end
  end
  
  describe '#reject!' do
    let(:validation) { create(:document_validation, status: 'pending') }
    
    it 'sets status to rejected with required comment' do
      validation.reject!(comment: 'Issues found')
      
      expect(validation.reload.status).to eq('rejected')
      expect(validation.validated_at).to be_present
      expect(validation.comment).to eq('Issues found')
    end
  end
  
  describe 'scopes' do
    let!(:pending_validation) { create(:document_validation, status: 'pending') }
    let!(:approved_validation) { create(:document_validation, status: 'approved') }
    let!(:rejected_validation) { create(:document_validation, status: 'rejected', comment: 'Issues') }
    
    it 'filters pending validations' do
      expect(DocumentValidation.pending_validation).to include(pending_validation)
      expect(DocumentValidation.pending_validation).not_to include(approved_validation)
    end
    
    it 'filters completed validations' do
      expect(DocumentValidation.completed).to include(approved_validation, rejected_validation)
      expect(DocumentValidation.completed).not_to include(pending_validation)
    end
    
    it 'filters by validator' do
      expect(DocumentValidation.for_validator(validator)).to be_empty
      expect(DocumentValidation.for_validator(pending_validation.validator)).to include(pending_validation)
    end
  end
end
