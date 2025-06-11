require 'rails_helper'

RSpec.describe DocumentMetadata, type: :model do
  let(:document) { create(:document) }
  let(:metadata_template) { create(:metadata_template) }
  let(:metadata_field) { create(:metadata_field, metadata_template: metadata_template) }
  
  describe 'associations' do
    it { is_expected.to belong_to(:document) }
    it { is_expected.to belong_to(:metadata_field) }
  end

  describe 'validations' do
    subject { build(:document_metadata, document: document, metadata_field: metadata_field) }
    
    it { is_expected.to validate_presence_of(:document) }
    it { is_expected.to validate_presence_of(:metadata_field) }
    it { is_expected.to validate_uniqueness_of(:metadata_field_id).scoped_to(:document_id) }
  end

  describe 'value validation' do
    let(:document_metadata) { build(:document_metadata, document: document, metadata_field: metadata_field) }

    context 'with string field type' do
      before { metadata_field.field_type = 'string' }

      it 'accepts string values' do
        document_metadata.value = 'Test String'
        expect(document_metadata).to be_valid
      end

      it 'validates max length if specified' do
        metadata_field.validation_rules = { 'max_length' => 10 }
        document_metadata.value = 'This is too long'
        expect(document_metadata).not_to be_valid
        expect(document_metadata.errors[:value]).to include('is too long')
      end
    end

    context 'with number field type' do
      before { metadata_field.field_type = 'number' }

      it 'accepts numeric values' do
        document_metadata.value = '123.45'
        expect(document_metadata).to be_valid
      end

      it 'rejects non-numeric values' do
        document_metadata.value = 'not a number'
        expect(document_metadata).not_to be_valid
      end

      it 'validates min/max if specified' do
        metadata_field.validation_rules = { 'min' => 0, 'max' => 100 }
        
        document_metadata.value = '150'
        expect(document_metadata).not_to be_valid
        
        document_metadata.value = '50'
        expect(document_metadata).to be_valid
      end
    end

    context 'with date field type' do
      before { metadata_field.field_type = 'date' }

      it 'accepts valid date formats' do
        document_metadata.value = '2024-01-15'
        expect(document_metadata).to be_valid
      end

      it 'rejects invalid date formats' do
        document_metadata.value = 'not-a-date'
        expect(document_metadata).not_to be_valid
      end
    end

    context 'with boolean field type' do
      before { metadata_field.field_type = 'boolean' }

      it 'accepts boolean values' do
        document_metadata.value = 'true'
        expect(document_metadata).to be_valid
        
        document_metadata.value = 'false'
        expect(document_metadata).to be_valid
      end
    end

    context 'with select field type' do
      before do 
        metadata_field.field_type = 'select'
        metadata_field.options = ['Option A', 'Option B', 'Option C']
      end

      it 'accepts values from options' do
        document_metadata.value = 'Option B'
        expect(document_metadata).to be_valid
      end

      it 'rejects values not in options' do
        document_metadata.value = 'Option D'
        expect(document_metadata).not_to be_valid
      end
    end

    context 'with required field' do
      before { metadata_field.required = true }

      it 'validates presence of value' do
        document_metadata.value = nil
        expect(document_metadata).not_to be_valid
        expect(document_metadata.errors[:value]).to include("can't be blank")
      end
    end
  end

  describe '#typed_value' do
    let(:document_metadata) { create(:document_metadata, document: document, metadata_field: metadata_field) }

    it 'returns typed value for number fields' do
      metadata_field.field_type = 'number'
      document_metadata.value = '123.45'
      expect(document_metadata.typed_value).to eq(123.45)
    end

    it 'returns typed value for boolean fields' do
      metadata_field.field_type = 'boolean'
      document_metadata.value = 'true'
      expect(document_metadata.typed_value).to eq(true)
    end

    it 'returns typed value for date fields' do
      metadata_field.field_type = 'date'
      document_metadata.value = '2024-01-15'
      expect(document_metadata.typed_value).to be_a(Date)
      expect(document_metadata.typed_value.to_s).to eq('2024-01-15')
    end

    it 'returns string value for other types' do
      metadata_field.field_type = 'string'
      document_metadata.value = 'Test'
      expect(document_metadata.typed_value).to eq('Test')
    end
  end

  describe '#display_value' do
    let(:document_metadata) { create(:document_metadata, document: document, metadata_field: metadata_field) }

    it 'formats boolean values' do
      metadata_field.field_type = 'boolean'
      document_metadata.value = 'true'
      expect(document_metadata.display_value).to eq('Oui')
      
      document_metadata.value = 'false'
      expect(document_metadata.display_value).to eq('Non')
    end

    it 'formats date values' do
      metadata_field.field_type = 'date'
      document_metadata.value = '2024-01-15'
      expect(document_metadata.display_value).to eq('15/01/2024')
    end

    it 'returns regular value for other types' do
      metadata_field.field_type = 'string'
      document_metadata.value = 'Test Value'
      expect(document_metadata.display_value).to eq('Test Value')
    end
  end

  describe 'callbacks' do
    it 'updates document updated_at when metadata changes' do
      document_metadata = create(:document_metadata, document: document, metadata_field: metadata_field)
      
      expect {
        document_metadata.update!(value: 'New Value')
        document.reload
      }.to change { document.updated_at }
    end
  end

  describe 'scopes' do
    let!(:required_metadata) do
      required_field = create(:metadata_field, metadata_template: metadata_template, required: true)
      create(:document_metadata, document: document, metadata_field: required_field, value: 'Required')
    end
    
    let!(:optional_metadata) do
      optional_field = create(:metadata_field, metadata_template: metadata_template, required: false)
      create(:document_metadata, document: document, metadata_field: optional_field, value: 'Optional')
    end

    describe '.required' do
      it 'returns only required metadata' do
        expect(DocumentMetadata.required).to include(required_metadata)
        expect(DocumentMetadata.required).not_to include(optional_metadata)
      end
    end

    describe '.by_field_name' do
      it 'finds metadata by field name' do
        field = create(:metadata_field, name: 'contract_number')
        metadata = create(:document_metadata, metadata_field: field)
        
        expect(DocumentMetadata.by_field_name('contract_number')).to include(metadata)
      end
    end
  end
end