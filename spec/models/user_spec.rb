require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should have_many(:documents).dependent(:destroy) }
    it { should have_many(:baskets).dependent(:destroy) }
    it { should have_many(:user_group_memberships).dependent(:destroy) }
    it { should have_many(:user_groups).through(:user_group_memberships) }
    it { should have_many(:notifications).dependent(:destroy) }
    it { should have_many(:search_queries).dependent(:destroy) }
    it { should have_many(:workflow_submissions).dependent(:destroy) }
    it { should have_many(:validation_requests).dependent(:destroy) }
    it { should have_many(:document_validations).dependent(:destroy) }
    it { should have_many(:authorizations).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:password) }
  end

  describe 'instance methods' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    describe '#full_name' do
      it 'returns the concatenated first and last name' do
        expect(user.full_name).to eq('John Doe')
      end
    end

    describe '#display_name' do
      context 'when user has first and last name' do
        it 'returns the full name' do
          expect(user.display_name).to eq('John Doe')
        end
      end

      context 'when user has no names' do
        let(:user) { build(:user, first_name: '', last_name: '') }
        
        before do
          user.save(validate: false)
        end
        
        it 'returns the email' do
          expect(user.display_name).to eq(user.email)
        end
      end
    end
  end

  describe 'traits' do
    describe 'admin trait' do
      let(:admin) { create(:user, :admin) }
      
      it 'creates an admin user' do
        expect(admin.role).to eq('admin')
      end
    end

    describe 'manager trait' do
      let(:manager) { create(:user, :manager) }
      
      it 'creates a manager user' do
        expect(manager.role).to eq('manager')
      end
    end

    describe 'with_documents trait' do
      let(:user) { create(:user, :with_documents) }
      
      it 'creates a user with documents' do
        expect(user.documents.count).to eq(5)
      end
    end
  end
end