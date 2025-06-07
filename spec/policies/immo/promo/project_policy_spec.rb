require 'rails_helper'

RSpec.describe Immo::Promo::ProjectPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, organization: organization, role: 'admin') }
  let(:super_admin) { create(:user, organization: organization, role: 'super_admin') }
  let(:other_org_user) { create(:user, organization: other_organization) }
  
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:other_org_project) { create(:immo_promo_project, organization: other_organization) }

  permissions :index?, :dashboard? do
    it 'grants access to all authenticated users' do
      expect(described_class).to permit(user, Immo::Promo::Project)
    end
  end

  permissions :show? do
    it 'grants access to project manager' do
      expect(described_class).to permit(user, project)
    end

    it 'grants access to users with read authorization' do
      reader = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: reader, permission_type: 'read')
      expect(described_class).to permit(reader, project)
    end

    it 'denies access to users from other organizations' do
      expect(described_class).not_to permit(other_org_user, project)
    end

    it 'grants access to admin users' do
      expect(described_class).to permit(admin_user, project)
    end
  end

  permissions :create? do
    it 'grants access to users with create permission' do
      allow(user).to receive(:has_permission?).with('immo_promo:projects:create').and_return(true)
      expect(described_class).to permit(user, Immo::Promo::Project.new)
    end

    it 'denies access to users without permission' do
      expect(described_class).not_to permit(user, Immo::Promo::Project.new)
    end

    it 'grants access to admin users' do
      expect(described_class).to permit(admin_user, Immo::Promo::Project.new)
    end
  end

  permissions :update? do
    it 'grants access to project manager' do
      expect(described_class).to permit(user, project)
    end

    it 'grants access to users with write authorization' do
      writer = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: writer, permission_type: 'write')
      expect(described_class).to permit(writer, project)
    end

    it 'denies access to users with only read authorization' do
      reader = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: reader, permission_type: 'read')
      expect(described_class).not_to permit(reader, project)
    end

    it 'denies access to users from other organizations' do
      expect(described_class).not_to permit(other_org_user, project)
    end
  end

  permissions :destroy? do
    it 'grants access to project manager with delete permission' do
      allow(user).to receive(:has_permission?).with('immo_promo:projects:delete').and_return(true)
      expect(described_class).to permit(user, project)
    end

    it 'denies access to project manager without delete permission' do
      expect(described_class).not_to permit(user, project)
    end

    it 'grants access to admin users' do
      expect(described_class).to permit(admin_user, project)
    end

    it 'denies access to other users even with write permission' do
      writer = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: writer, permission_type: 'write')
      allow(writer).to receive(:has_permission?).with('immo_promo:projects:delete').and_return(true)
      expect(described_class).not_to permit(writer, project)
    end
  end

  describe 'Scope' do
    let!(:user_project) { create(:immo_promo_project, organization: organization, project_manager: user) }
    let!(:org_project) { create(:immo_promo_project, organization: organization) }
    let!(:other_org_project) { create(:immo_promo_project, organization: other_organization) }

    it 'includes projects where user is project manager' do
      scope = Pundit.policy_scope!(user, Immo::Promo::Project)
      expect(scope).to include(user_project)
      expect(scope).not_to include(org_project, other_org_project)
    end

    it 'includes projects with read authorization' do
      create(:authorization, authorizable: org_project, user: user, permission_type: 'read')
      scope = Pundit.policy_scope!(user, Immo::Promo::Project)
      expect(scope).to include(user_project, org_project)
      expect(scope).not_to include(other_org_project)
    end

    it 'includes all organization projects for admin' do
      scope = Pundit.policy_scope!(admin_user, Immo::Promo::Project)
      expect(scope).to include(user_project, org_project)
      expect(scope).not_to include(other_org_project)
    end

    it 'includes all projects for super admin' do
      scope = Pundit.policy_scope!(super_admin, Immo::Promo::Project)
      expect(scope).to include(user_project, org_project, other_org_project)
    end
  end
end