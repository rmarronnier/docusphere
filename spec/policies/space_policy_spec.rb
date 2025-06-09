require 'rails_helper'

RSpec.describe SpacePolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:user, organization: organization, role: 'admin') }
  let(:super_admin) { create(:user, organization: organization, role: 'super_admin') }
  let(:other_user) { create(:user, organization: other_organization) }
  let(:space) { create(:space, organization: organization) }
  let(:other_space) { create(:space, organization: other_organization) }
  
  subject { described_class }

  permissions :show?, :create?, :update?, :destroy? do
    context 'when user is nil' do
      it 'denies access' do
        expect(subject).not_to permit(nil, space)
      end
    end

    context 'when user is from same organization' do
      it 'grants access to regular user' do
        expect(subject).to permit(user, space)
      end

      it 'grants access to admin' do
        expect(subject).to permit(admin, space)
      end

      it 'grants access to super admin' do
        expect(subject).to permit(super_admin, space)
      end
    end

    context 'when user is from different organization' do
      it 'denies access to regular user' do
        expect(subject).not_to permit(other_user, space)
      end
    end
  end

  describe 'Scope' do
    let!(:user_space) { create(:space, organization: organization) }
    let!(:other_org_space) { create(:space, organization: other_organization) }

    context 'when user is nil' do
      it 'returns empty scope' do
        scope = SpacePolicy::Scope.new(nil, Space).resolve
        expect(scope).to be_empty
      end
    end

    context 'when user is super admin' do
      it 'returns all spaces' do
        scope = SpacePolicy::Scope.new(super_admin, Space).resolve
        expect(scope).to include(user_space)
        expect(scope).to include(other_org_space)
      end
    end

    context 'when user is regular user or admin' do
      it 'returns only spaces from user organization for regular user' do
        scope = SpacePolicy::Scope.new(user, Space).resolve
        expect(scope).to include(user_space)
        expect(scope).not_to include(other_org_space)
      end

      it 'returns only spaces from user organization for admin' do
        scope = SpacePolicy::Scope.new(admin, Space).resolve
        expect(scope).to include(user_space)
        expect(scope).not_to include(other_org_space)
      end
    end

    context 'when user is from different organization' do
      it 'returns only spaces from user organization' do
        scope = SpacePolicy::Scope.new(other_user, Space).resolve
        expect(scope).not_to include(user_space)
        expect(scope).to include(other_org_space)
      end
    end
  end
end