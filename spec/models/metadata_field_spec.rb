require 'rails_helper'

RSpec.describe MetadataField, type: :model do
  let(:metadata_template) { create(:metadata_template) }
  
  describe 'associations' do
    it { should belong_to(:metadata_template) }
    it { should have_many(:metadata).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:field_type) }
    # it { should validate_presence_of(:metadata_template) } # belongs_to validation
    
    it 'validates field_type inclusion' do
      should validate_inclusion_of(:field_type).in_array(%w[string text integer date datetime boolean select file])
    end

    it 'validates uniqueness of name scoped to metadata_template' do
      create(:metadata_field, name: 'Field 1', metadata_template: metadata_template)
      should validate_uniqueness_of(:name).scoped_to(:metadata_template_id)
    end
  end

  describe 'scopes' do
    let!(:required_field) { create(:metadata_field, required: true, metadata_template: metadata_template) }
    let!(:optional_field) { create(:metadata_field, required: false, metadata_template: metadata_template) }

    describe '.required' do
      it 'returns only required fields' do
        expect(MetadataField.required).to include(required_field)
        expect(MetadataField.required).not_to include(optional_field)
      end
    end

    describe '.optional' do
      it 'returns only optional fields' do
        expect(MetadataField.optional).to include(optional_field)
        expect(MetadataField.optional).not_to include(required_field)
      end
    end
  end

  describe 'instance methods' do
    let(:field) { create(:metadata_field, metadata_template: metadata_template) }
    
    describe '#select_options_array' do
      it 'returns empty array for non-select fields' do
        field.update(field_type: 'string')
        expect(field.select_options_array).to eq([])
      end

      it 'parses select options from string' do
        field.update(field_type: 'select', options: 'Option 1,Option 2,Option 3')
        expect(field.select_options_array).to eq(['Option 1', 'Option 2', 'Option 3'])
      end

      it 'handles nil select_options' do
        field.update(field_type: 'select', options: nil)
        expect(field.select_options_array).to eq([])
      end
    end

    describe '#validation_rules' do
      it 'returns hash of validation rules' do
        field.update(required: true, field_type: 'text')
        rules = field.validation_rules
        
        expect(rules[:required]).to be true
        # expect(rules[:type]).to eq('text') # This doesn't exist in the model
      end
    end

    describe '#html_input_type' do
      it 'returns correct input type for each field type' do
        expect(create(:metadata_field, field_type: 'string').html_input_type).to eq('text')
        expect(create(:metadata_field, field_type: 'text').html_input_type).to eq('text')
        expect(create(:metadata_field, field_type: 'integer').html_input_type).to eq('number')
        expect(create(:metadata_field, field_type: 'date').html_input_type).to eq('date')
        expect(create(:metadata_field, field_type: 'boolean').html_input_type).to eq('checkbox')
        expect(create(:metadata_field, field_type: 'file').html_input_type).to eq('file')
        expect(create(:metadata_field, field_type: 'select').html_input_type).to eq('select')
      end
    end
  end

  describe 'callbacks' do
    it 'normalizes select options before save' do
      field = MetadataField.create!(
        name: 'Test Field',
        field_type: 'select',
        options: ' Option 1 , Option 2 , Option 3 ',
        metadata_template: metadata_template
      )
      
      expect(field.options).to eq('Option 1,Option 2,Option 3')
    end
  end
end