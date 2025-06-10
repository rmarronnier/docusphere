require 'rails_helper'

RSpec.describe FolderPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: other_organization) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, space: space) }
  let(:other_space) { create(:space, organization: other_organization) }
  let(:other_folder) { create(:folder, space: other_space) }
  
  subject { described_class }

  permissions :show?, :create?, :update?, :destroy? do
    context 'when user is nil' do
      it 'denies access' do
        expect(subject).not_to permit(nil, folder)
      end
    end

    context 'when folder is in user organization' do
      it 'grants access' do
        expect(subject).to permit(user, folder)
      end
    end

    context 'when folder is in different organization' do
      it 'denies access' do
        expect(subject).not_to permit(other_user, folder)
      end
    end
  end

  describe 'Scope' do
    let!(:user_folder) { create(:folder, space: space) }
    let!(:other_org_folder) { create(:folder, space: other_space) }

    it 'returns only folders from user organization spaces' do
      scope = FolderPolicy::Scope.new(user, Folder).resolve
      expect(scope).to include(user_folder)
      expect(scope).not_to include(other_org_folder)
    end

    it 'returns empty scope for nil user' do
      scope = FolderPolicy::Scope.new(nil, Folder).resolve
      expect(scope).to be_empty
    end
  end

  describe '#permitted_attributes' do
    let(:policy) { described_class.new(user, folder) }
    let(:admin_user) { create(:user, :admin, organization: organization) }
    let(:super_admin) { create(:user, :super_admin) }
    
    it "returns the correct permitted attributes" do
      expect(policy.permitted_attributes).to contain_exactly(:name, :description, :slug, :position, :is_active, metadata: {})
    end
    
    it "returns the same attributes for all users" do
      admin_policy = described_class.new(admin_user, folder)
      super_admin_policy = described_class.new(super_admin, folder)
      
      expect(admin_policy.permitted_attributes).to eq(policy.permitted_attributes)
      expect(super_admin_policy.permitted_attributes).to eq(policy.permitted_attributes)
    end
  end
end