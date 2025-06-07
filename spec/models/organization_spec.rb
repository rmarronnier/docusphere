require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'associations' do
    it { should have_many(:spaces).dependent(:destroy) }
    it { should have_many(:users).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:organization) }
    
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe 'callbacks' do
    describe 'slug generation' do
      context 'when slug is blank' do
        let(:organization) { build(:organization, name: 'Test Organization', slug: '') }
        
        it 'generates slug from name' do
          organization.valid?
          expect(organization.slug).to eq('test-organization')
        end
      end

      context 'when slug is present' do
        let(:organization) { build(:organization, name: 'Test Organization', slug: 'custom-slug') }
        
        it 'does not override existing slug' do
          organization.valid?
          expect(organization.slug).to eq('custom-slug')
        end
      end
    end
  end

  describe 'factory' do
    it 'creates a valid organization' do
      organization = create(:organization)
      expect(organization).to be_valid
      expect(organization.slug).to be_present
    end

    describe 'with_spaces trait' do
      let(:organization) { create(:organization, :with_spaces) }
      
      it 'creates an organization with spaces' do
        expect(organization.spaces.count).to eq(3)
      end
    end
  end
end