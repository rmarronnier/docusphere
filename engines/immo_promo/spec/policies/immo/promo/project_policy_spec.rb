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

  describe 'dashboard?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:dashboard) }
    end
    
    context 'with user having immo_promo:access permission' do
      subject { described_class.new(controller_user, project) }
      it { is_expected.to permit_action(:dashboard) }
    end
    
    context 'with user having immo_promo:read permission' do
      let(:read_user) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:read' => true }
        ) 
      }
      subject { described_class.new(read_user, project) }
      it { is_expected.to permit_action(:dashboard) }
    end
    
    context 'with user without permissions' do
      subject { described_class.new(regular_user, project) }
      it { is_expected.not_to permit_action(:dashboard) }
    end
  end

  describe 'update?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with user having write authorization' do
      before do
        create(:authorization,
          authorizable: project,
          user: regular_user,
          permission_level: 'write'
        )
      end
      subject { described_class.new(regular_user, project) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with user having immo_promo:projects:write permission' do
      let(:write_user) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:projects:write' => true }
        ) 
      }
      subject { described_class.new(write_user, project) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with user having immo_promo:write permission' do
      let(:write_user) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:write' => true }
        ) 
      }
      subject { described_class.new(write_user, project) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, project) }
      it { is_expected.not_to permit_action(:update) }
    end
    
    context 'with user without write permissions' do
      subject { described_class.new(regular_user, project) }
      it { is_expected.not_to permit_action(:update) }
    end
  end

  describe 'destroy?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with project manager having delete permission' do
      let(:project_with_delete_manager) { 
        create(:immo_promo_project, 
          organization: organization, 
          project_manager: create(:user, 
            organization: organization,
            permissions: { 'immo_promo:projects:delete' => true }
          )
        ) 
      }
      subject { described_class.new(project_with_delete_manager.project_manager, project_with_delete_manager) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with project manager without delete permission' do
      subject { described_class.new(project_manager, project_with_manager) }
      it { is_expected.not_to permit_action(:destroy) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, project) }
      it { is_expected.not_to permit_action(:destroy) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, project) }
      it { is_expected.not_to permit_action(:destroy) }
    end
  end

  describe 'manage_stakeholders?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:manage_stakeholders) }
    end
    
    context 'with user having stakeholders:manage permission' do
      let(:stakeholder_manager) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:stakeholders:manage' => true }
        ) 
      }
      subject { described_class.new(stakeholder_manager, project) }
      it { is_expected.to permit_action(:manage_stakeholders) }
    end
    
    context 'with user having update permission' do
      subject { described_class.new(manager_user, project) }
      it { is_expected.to permit_action(:manage_stakeholders) }
    end
    
    context 'with user without permissions' do
      subject { described_class.new(regular_user, project) }
      it { is_expected.not_to permit_action(:manage_stakeholders) }
    end
  end

  describe 'manage_budget?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:manage_budget) }
    end
    
    context 'with user having budget:manage permission' do
      subject { described_class.new(finance_user, project) }
      it { is_expected.to permit_action(:manage_budget) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, project_with_manager) }
      it { is_expected.to permit_action(:manage_budget) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, project) }
      it { is_expected.not_to permit_action(:manage_budget) }
    end
    
    context 'with user without budget permissions' do
      subject { described_class.new(regular_user, project) }
      it { is_expected.not_to permit_action(:manage_budget) }
    end
  end

  describe 'manage_permits?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:manage_permits) }
    end
    
    context 'with user having permits:manage permission' do
      let(:permit_manager) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:permits:manage' => true }
        ) 
      }
      subject { described_class.new(permit_manager, project) }
      it { is_expected.to permit_action(:manage_permits) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, project_with_manager) }
      it { is_expected.to permit_action(:manage_permits) }
    end
    
    context 'with user having legal:manage permission' do
      let(:legal_manager) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:legal:manage' => true }
        ) 
      }
      subject { described_class.new(legal_manager, project) }
      it { is_expected.to permit_action(:manage_permits) }
    end
    
    context 'with user without permit permissions' do
      subject { described_class.new(regular_user, project) }
      it { is_expected.not_to permit_action(:manage_permits) }
    end
  end

  describe 'view_financial_data?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, project) }
      it { is_expected.to permit_action(:view_financial_data) }
    end
    
    context 'with user having financial:read permission' do
      subject { described_class.new(finance_user, project) }
      it { is_expected.to permit_action(:view_financial_data) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, project_with_manager) }
      it { is_expected.to permit_action(:view_financial_data) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, project) }
      it { is_expected.not_to permit_action(:view_financial_data) }
    end
    
    context 'with user without financial permissions' do
      subject { described_class.new(regular_user, project) }
      it { is_expected.not_to permit_action(:view_financial_data) }
    end
  end

  describe 'document-related permissions' do
    describe 'preview?' do
      context 'with user who can show project' do
        subject { described_class.new(controller_user, project) }
        it { is_expected.to permit_action(:preview) }
      end
      
      context 'with user who cannot show project' do
        subject { described_class.new(regular_user, project) }
        it { is_expected.not_to permit_action(:preview) }
      end
    end

    describe 'share?' do
      context 'with user who can update project' do
        subject { described_class.new(manager_user, project) }
        it { is_expected.to permit_action(:share) }
      end
      
      context 'with user who cannot update project' do
        subject { described_class.new(regular_user, project) }
        it { is_expected.not_to permit_action(:share) }
      end
    end

    describe 'request_validation?' do
      context 'with user who can update project' do
        subject { described_class.new(manager_user, project) }
        it { is_expected.to permit_action(:request_validation) }
      end
      
      context 'with user who cannot update project' do
        subject { described_class.new(regular_user, project) }
        it { is_expected.not_to permit_action(:request_validation) }
      end
    end

    describe 'bulk_actions?' do
      context 'with user who can update project' do
        subject { described_class.new(manager_user, project) }
        it { is_expected.to permit_action(:bulk_actions) }
      end
      
      context 'with user who cannot update project' do
        subject { described_class.new(regular_user, project) }
        it { is_expected.not_to permit_action(:bulk_actions) }
      end
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
    
    context 'with project manager having immo_promo:access' do
      let!(:managed_project) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }
      
      subject { described_class::Scope.new(project_manager, Immo::Promo::Project).resolve }
      
      it 'returns all projects in organization (because has immo_promo:access)' do
        expect(subject).to include(managed_project, org_project1, org_project2)
        expect(subject).not_to include(other_org_project)
      end
    end
    
    context 'with project manager without immo_promo:access' do
      let(:limited_manager) { create(:user, role: 'user', organization: organization) }
      let!(:managed_project) { create(:immo_promo_project, organization: organization, project_manager: limited_manager) }
      
      subject { described_class::Scope.new(limited_manager, Immo::Promo::Project).resolve }
      
      it 'returns only projects they manage' do
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

  describe '#permitted_attributes' do
    let(:policy) { described_class.new(regular_user, project) }
    let(:manager_policy) { described_class.new(project_manager, project) }
    let(:admin_policy) { described_class.new(admin_user, project) }
    
    it "returns base attributes for regular users" do
      expect(policy.permitted_attributes).to contain_exactly(
        :name, :slug, :description, :reference_number, :project_type, 
        :status, :address, :city, :postal_code, :country, :latitude, 
        :longitude, :total_area, :land_area, :buildable_surface_area, 
        :total_units, :start_date, :expected_completion_date, 
        :building_permit_number, metadata: {}
      )
    end
    
    it "returns extended attributes for project managers" do
      expect(manager_policy.permitted_attributes).to include(
        :total_budget_cents, :current_budget_cents, :actual_end_date
      )
    end
    
    it "returns extended attributes for admins" do
      expect(admin_policy.permitted_attributes).to include(
        :total_budget_cents, :current_budget_cents, :actual_end_date
      )
    end
  end
end
