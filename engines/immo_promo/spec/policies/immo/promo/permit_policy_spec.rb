require 'rails_helper'

RSpec.describe Immo::Promo::PermitPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:permit) { create(:immo_promo_permit, project: project) }
  
  # Users with different roles
  let(:super_admin) { create(:user, role: 'super_admin') }
  let(:admin_user) { create(:user, role: 'admin', organization: organization) }
  let(:project_manager) { 
    create(:user, 
      role: 'user', 
      organization: organization,
      permissions: { 'immo_promo:access' => true }
    ) 
  }
  let(:regular_user) { create(:user, role: 'user', organization: organization) }
  let(:external_user) { create(:user, role: 'user', organization: create(:organization)) }
  
  let(:project_with_manager) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }
  let(:permit_with_manager) { create(:immo_promo_permit, project: project_with_manager) }

  describe 'index?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, permit) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with admin user' do
      subject { described_class.new(admin_user, permit) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with user having immo_promo:access permission' do
      subject { described_class.new(project_manager, permit) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with regular user without immo_promo access' do
      subject { described_class.new(regular_user, permit) }
      it { is_expected.not_to permit_action(:index) }
    end
    
    context 'with external user' do
      subject { described_class.new(external_user, permit) }
      it { is_expected.not_to permit_action(:index) }
    end
  end

  describe 'show?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, permit) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with admin from same organization' do
      subject { described_class.new(admin_user, permit) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, permit_with_manager) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, permit) }
      it { is_expected.not_to permit_action(:show) }
    end
    
    context 'with regular user from same organization' do
      subject { described_class.new(regular_user, permit) }
      it { is_expected.not_to permit_action(:show) }
    end
  end

  describe 'create?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, permit) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with admin from same organization' do
      subject { described_class.new(admin_user, permit) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, permit_with_manager) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, permit) }
      it { is_expected.not_to permit_action(:create) }
    end
    
    context 'with regular user from same organization' do
      subject { described_class.new(regular_user, permit) }
      it { is_expected.not_to permit_action(:create) }
    end
  end

  describe 'update?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, permit) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with admin from same organization' do
      subject { described_class.new(admin_user, permit) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, permit_with_manager) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, permit) }
      it { is_expected.not_to permit_action(:update) }
    end
    
    context 'with regular user from same organization' do
      subject { described_class.new(regular_user, permit) }
      it { is_expected.not_to permit_action(:update) }
    end
  end

  describe 'destroy?' do
    context 'with draft permit' do
      let(:draft_permit) { create(:immo_promo_permit, project: project_with_manager, status: 'draft') }
      
      context 'with super admin' do
        subject { described_class.new(super_admin, draft_permit) }
        it { is_expected.to permit_action(:destroy) }
      end
      
      context 'with project manager' do
        subject { described_class.new(project_manager, draft_permit) }
        it { is_expected.to permit_action(:destroy) }
      end
    end
    
    context 'with submitted permit' do
      let(:submitted_permit) { create(:immo_promo_permit, project: project_with_manager, status: 'submitted') }
      
      context 'with super admin' do
        subject { described_class.new(super_admin, submitted_permit) }
        it { is_expected.not_to permit_action(:destroy) }
      end
      
      context 'with project manager' do
        subject { described_class.new(project_manager, submitted_permit) }
        it { is_expected.not_to permit_action(:destroy) }
      end
    end
    
    context 'with user from different organization' do
      let(:draft_permit) { create(:immo_promo_permit, project: project, status: 'draft') }
      subject { described_class.new(external_user, draft_permit) }
      it { is_expected.not_to permit_action(:destroy) }
    end
  end

  describe 'submit_for_approval?' do
    context 'with draft permit' do
      let(:draft_permit) { create(:immo_promo_permit, project: project_with_manager, status: 'draft') }
      
      context 'with super admin' do
        subject { described_class.new(super_admin, draft_permit) }
        it { is_expected.to permit_action(:submit_for_approval) }
      end
      
      context 'with project manager' do
        subject { described_class.new(project_manager, draft_permit) }
        it { is_expected.to permit_action(:submit_for_approval) }
      end
    end
    
    context 'with submitted permit' do
      let(:submitted_permit) { create(:immo_promo_permit, project: project_with_manager, status: 'submitted') }
      
      context 'with project manager' do
        subject { described_class.new(project_manager, submitted_permit) }
        it { is_expected.not_to permit_action(:submit_for_approval) }
      end
    end
    
    context 'with user who cannot manage project' do
      let(:draft_permit) { create(:immo_promo_permit, project: project, status: 'draft') }
      subject { described_class.new(regular_user, draft_permit) }
      it { is_expected.not_to permit_action(:submit_for_approval) }
    end
  end

  describe 'approve?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, permit) }
      it { is_expected.to permit_action(:approve) }
    end
    
    context 'with admin user' do
      subject { described_class.new(admin_user, permit) }
      it { is_expected.to permit_action(:approve) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, permit_with_manager) }
      it { is_expected.not_to permit_action(:approve) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, permit) }
      it { is_expected.not_to permit_action(:approve) }
    end
  end

  describe 'reject?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, permit) }
      it { is_expected.to permit_action(:reject) }
    end
    
    context 'with admin user' do
      subject { described_class.new(admin_user, permit) }
      it { is_expected.to permit_action(:reject) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, permit_with_manager) }
      it { is_expected.not_to permit_action(:reject) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, permit) }
      it { is_expected.not_to permit_action(:reject) }
    end
  end

  describe 'Scope' do
    let!(:org_permit1) { create(:immo_promo_permit, project: create(:immo_promo_project, organization: organization)) }
    let!(:org_permit2) { create(:immo_promo_permit, project: create(:immo_promo_project, organization: organization)) }
    let!(:other_org_permit) { create(:immo_promo_permit, project: create(:immo_promo_project)) }
    
    context 'with super admin' do
      subject { described_class::Scope.new(super_admin, Immo::Promo::Permit).resolve }
      
      it 'returns all permits' do
        expect(subject).to include(org_permit1, org_permit2, other_org_permit)
      end
    end
    
    context 'with admin user' do
      subject { described_class::Scope.new(admin_user, Immo::Promo::Permit).resolve }
      
      it 'returns all permits' do
        expect(subject).to include(org_permit1, org_permit2, other_org_permit)
      end
    end
    
    context 'with regular user' do
      subject { described_class::Scope.new(regular_user, Immo::Promo::Permit).resolve }
      
      it 'returns permits from same organization' do
        expect(subject).to include(org_permit1, org_permit2)
        expect(subject).not_to include(other_org_permit)
      end
    end
    
    context 'with external user' do
      subject { described_class::Scope.new(external_user, Immo::Promo::Permit).resolve }
      
      it 'returns no permits' do
        expect(subject).not_to include(org_permit1, org_permit2, other_org_permit)
      end
    end
  end
end