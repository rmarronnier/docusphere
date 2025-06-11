require 'rails_helper'

RSpec.describe MetadataTemplate, type: :model do
  let(:organization) { create(:organization) }
  
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should have_many(:metadata_fields).dependent(:destroy) }
    it { should have_many(:documents) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    
    it 'validates uniqueness of name scoped to organization' do
      create(:metadata_template, name: 'Template 1', organization: organization)
      should validate_uniqueness_of(:name).scoped_to(:organization_id)
    end
  end

  describe 'scopes' do
    let!(:active_template) { create(:metadata_template, is_active: true, organization: organization) }
    let!(:inactive_template) { create(:metadata_template, is_active: false, organization: organization) }

    describe '.active' do
      it 'returns only active templates' do
        expect(MetadataTemplate.active).to include(active_template)
        expect(MetadataTemplate.active).not_to include(inactive_template)
      end
    end
  end

  describe 'instance methods' do
    let(:template) { create(:metadata_template, organization: organization) }
    
    describe '#is_active' do
      it 'has a default value of true' do
        new_template = MetadataTemplate.new(name: 'Test', organization: organization)
        expect(new_template.is_active).to be true
      end
      
      it 'can be set to false' do
        template.update(is_active: false)
        expect(template.reload.is_active).to be false
      end
    end

    describe '#field_names' do
      it 'returns array of field names' do
        create(:metadata_field, name: 'Field 1', metadata_template: template)
        create(:metadata_field, name: 'Field 2', metadata_template: template)
        
        expect(template.field_names).to contain_exactly('Field 1', 'Field 2')
      end
    end
  end
end