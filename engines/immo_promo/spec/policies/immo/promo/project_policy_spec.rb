require 'rails_helper'

RSpec.describe Immo::Promo::ProjectPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  
  # Users with different roles and permissions
  let(:super_admin) { create(:user, role: 'super_admin') }
  let(:admin_user) { create(:user, role: 'admin', organization: organization) }
  let(:manager_user) { 
    create(:user, 
      role: 'manager', 
      organization: organization,
      permissions: { 
        'immo_promo:access' => true,
        'immo_promo:projects:create' => true,
        'immo_promo:projects:write' => true
      }
    ) 
  }
  
  let(:controller_user) {
    create(:user,
      role: 'manager',
      organization: organization,
      permissions: { 'immo_promo:access' => true }
    )
  }
  
  let(:project_manager) { 
    create(:user, 
      role: 'user', 
      organization: organization,
      permissions: { 'immo_promo:access' => true }
    ) 
  }
  
  let(:finance_user) {
    create(:user,
      role: 'user',
      organization: organization,
      permissions: { 
        'immo_promo:access' => true,
        'immo_promo:financial:read' => true,
        'immo_promo:budget:manage' => true
      }
    )
  }
  
  let(:regular_user) { create(:user, role: 'user', organization: organization) }
  let(:external_user) { create(:user, role: 'user', organization: create(:organization)) }
  
  let(:project_with_manager) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }

  describe 'index?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, project) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with user having immo_promo:access permission' do
      subject { described_class.new(controller_user, project) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with user having immo_promo:read permission' do
      let(:read_user) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:read' => true }
        ) 
      }
      subject { described_class.new(read_user, project) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with user without permissions' do
      subject { described_class.new(regular_user, project) }
      it { is_expected.not_to permit_action(:index) }
    end
    
    context 'with external user' do
      subject { described_class.new(external_user, project) }
      it { is_expected.not_to permit_action(:index) }
    end
  end

  describe 'show?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with user having immo_promo:access permission' do
      subject { described_class.new(controller_user, project) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with user having immo_promo:read permission' do
      let(:read_user) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:read' => true }
        ) 
      }
      subject { described_class.new(read_user, project) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, project_with_manager) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with user having direct read authorization' do
      before do
        create(:authorization,
          authorizable: project,
          user: regular_user,
          permission_level: 'read'
        )
      end
      subject { described_class.new(regular_user, project) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, project) }
      it { is_expected.not_to permit_action(:show) }
    end
    
    context 'with user without permissions' do
      subject { described_class.new(regular_user, project) }
      it { is_expected.not_to permit_action(:show) }
    end
  end

  describe 'create?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with user having projects:create permission' do
      subject { described_class.new(manager_user, project) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with user having immo_promo:projects:create permission' do
      let(:create_user) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:projects:create' => true }
        ) 
      }
      subject { described_class.new(create_user, project) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with user without create permissions' do
      subject { described_class.new(controller_user, project) }
      it { is_expected.not_to permit_action(:create) }
    end
    
    context 'with external user' do
      subject { described_class.new(external_user, project) }
      it { is_expected.not_to permit_action(:create) }
    end
  end

  describe 'Scope' do
    let!(:org_project1) { create(:immo_promo_project, organization: organization) }
    let!(:org_project2) { create(:immo_promo_project, organization: organization) }
    let!(:other_org_project) { create(:immo_promo_project) }
    
    context 'with super admin' do
      subject { described_class::Scope.new(super_admin, Immo::Promo::Project).resolve }
      
      it 'returns all projects' do
        expect(subject).to include(org_project1, org_project2, other_org_project)
      end
    end
    
    context 'with admin user' do
      subject { described_class::Scope.new(admin_user, Immo::Promo::Project).resolve }
      
      it 'returns all projects in organization' do
        expect(subject).to include(org_project1, org_project2)
        expect(subject).not_to include(other_org_project)
      end
    end
    
    context 'with user having immo_promo:access permission' do
      subject { described_class::Scope.new(controller_user, Immo::Promo::Project).resolve }
      
      it 'returns all projects in organization' do
        expect(subject).to include(org_project1, org_project2)
        expect(subject).not_to include(other_org_project)
      end
    end
    
    context 'with project manager' do
      let!(:managed_project) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }
      
      subject { described_class::Scope.new(project_manager, Immo::Promo::Project).resolve }
      
      it 'returns projects they manage' do
        expect(subject).to include(managed_project)
        expect(subject).not_to include(org_project1, org_project2)
      end
    end
    
    context 'with user having specific project authorization' do
      before do
        create(:authorization,
          authorizable: org_project1,
          user: regular_user,
          permission_level: 'read'
        )
      end
      
      subject { described_class::Scope.new(regular_user, Immo::Promo::Project).resolve }
      
      it 'returns projects they have authorization for' do
        expect(subject).to include(org_project1)
        expect(subject).not_to include(org_project2, other_org_project)
      end
    end
    
    context 'with external user' do
      subject { described_class::Scope.new(external_user, Immo::Promo::Project).resolve }
      
      it 'returns no projects' do
        expect(subject).to be_empty
      end
    end
  end
end
