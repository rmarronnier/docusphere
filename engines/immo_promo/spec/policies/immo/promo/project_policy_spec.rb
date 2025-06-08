require 'rails_helper'

RSpec.describe Immo::Promo::ProjectPolicy do
  let(:organization) { create(:organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:project_manager) { create(:user, organization: organization) }
  let(:regular_user) { create(:user, organization: organization) }
  let(:other_user) { create(:user) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }

  describe 'for an admin user' do
    subject { described_class.new(admin, project) }

    it { should permit_action(:index) }
    it { should permit_action(:show) }
    it { should permit_action(:new) }
    it { should permit_action(:create) }
    it { should permit_action(:edit) }
    it { should permit_action(:update) }
    it { should permit_action(:destroy) }
    it { should permit_action(:dashboard) }
  end

  describe 'for a project manager' do
    subject { described_class.new(project_manager, project) }

    before do
      project_manager.add_permission('immo_promo:read')
      project_manager.add_permission('immo_promo:write')
    end

    it { should permit_action(:index) }
    it { should permit_action(:show) }
    it { should permit_action(:edit) }
    it { should permit_action(:update) }
    it { should permit_action(:dashboard) }
    it { should_not permit_action(:destroy) }
  end

  describe 'for a regular user with read permission' do
    subject { described_class.new(regular_user, project) }

    before do
      regular_user.add_permission('immo_promo:read')
    end

    it { should permit_action(:index) }
    it { should permit_action(:show) }
    it { should permit_action(:dashboard) }
    it { should_not permit_action(:edit) }
    it { should_not permit_action(:update) }
    it { should_not permit_action(:destroy) }
  end

  describe 'for a user from another organization' do
    subject { described_class.new(other_user, project) }

    it { should_not permit_action(:index) }
    it { should_not permit_action(:show) }
    it { should_not permit_action(:edit) }
    it { should_not permit_action(:update) }
    it { should_not permit_action(:destroy) }
    it { should_not permit_action(:dashboard) }
  end

  describe 'scope' do
    let!(:org_project) { project }
    let!(:other_project) { create(:immo_promo_project) }

    it 'includes projects from same organization for users with permission' do
      regular_user.add_permission('immo_promo:read')
      scope = described_class::Scope.new(regular_user, Immo::Promo::Project.all)

      expect(scope.resolve).to include(org_project)
      expect(scope.resolve).not_to include(other_project)
    end

    it 'includes all projects for admin' do
      scope = described_class::Scope.new(admin, Immo::Promo::Project.all)

      expect(scope.resolve).to include(org_project)
      expect(scope.resolve).to include(other_project)
    end
  end
end
