require 'rails_helper'

RSpec.describe Immo::Promo::StakeholderPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
  
  let(:admin_user) { create(:user, role: 'admin', organization: organization) }
  let(:project_manager) { create(:user, role: 'user', organization: organization) }
  let(:regular_user) { create(:user, role: 'user', organization: organization) }
  let(:external_user) { create(:user, role: 'user', organization: create(:organization)) }
  
  let(:project_with_manager) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }
  let(:stakeholder_with_manager) { create(:immo_promo_stakeholder, project: project_with_manager) }

  describe 'index?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, stakeholder) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, stakeholder_with_manager) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with user having stakeholders:manage permission' do
      let(:stakeholder_manager) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:stakeholders:manage' => true }
        ) 
      }
      subject { described_class.new(stakeholder_manager, stakeholder) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with external user' do
      subject { described_class.new(external_user, stakeholder) }
      it { is_expected.not_to permit_action(:index) }
    end
  end

  describe 'show?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, stakeholder) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, stakeholder_with_manager) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with user having read permission on project' do
      before do
        create(:authorization,
          authorizable: project,
          user: regular_user,
          permission_level: 'read'
        )
      end
      subject { described_class.new(regular_user, stakeholder) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with external user' do
      subject { described_class.new(external_user, stakeholder) }
      it { is_expected.not_to permit_action(:show) }
    end
  end

  describe 'create?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, stakeholder) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, stakeholder_with_manager) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with user having stakeholders:manage permission' do
      let(:stakeholder_manager) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:stakeholders:manage' => true }
        ) 
      }
      subject { described_class.new(stakeholder_manager, stakeholder) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, stakeholder) }
      it { is_expected.not_to permit_action(:create) }
    end
  end

  describe 'update?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, stakeholder) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, stakeholder_with_manager) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with user having stakeholders:manage permission' do
      let(:stakeholder_manager) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:stakeholders:manage' => true }
        ) 
      }
      subject { described_class.new(stakeholder_manager, stakeholder) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, stakeholder) }
      it { is_expected.not_to permit_action(:update) }
    end
  end

  describe 'destroy?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, stakeholder) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, stakeholder_with_manager) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with user having stakeholders:manage permission' do
      let(:stakeholder_manager) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:stakeholders:manage' => true }
        ) 
      }
      subject { described_class.new(stakeholder_manager, stakeholder) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, stakeholder) }
      it { is_expected.not_to permit_action(:destroy) }
    end
  end

  describe 'qualify?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, stakeholder) }
      it { is_expected.to permit_action(:qualify) }
    end
    
    context 'with user having stakeholders:manage permission' do
      let(:stakeholder_manager) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:stakeholders:manage' => true }
        ) 
      }
      subject { described_class.new(stakeholder_manager, stakeholder) }
      it { is_expected.to permit_action(:qualify) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, stakeholder) }
      it { is_expected.not_to permit_action(:qualify) }
    end
  end

  describe 'allocate?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, stakeholder) }
      it { is_expected.to permit_action(:allocate) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, stakeholder_with_manager) }
      it { is_expected.to permit_action(:allocate) }
    end
    
    context 'with user having stakeholders:manage permission' do
      let(:stakeholder_manager) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:stakeholders:manage' => true }
        ) 
      }
      subject { described_class.new(stakeholder_manager, stakeholder) }
      it { is_expected.to permit_action(:allocate) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, stakeholder) }
      it { is_expected.not_to permit_action(:allocate) }
    end
  end

  describe '#permitted_attributes' do
    let(:policy) { described_class.new(admin_user, stakeholder) }
    
    it 'returns the expected attributes' do
      expected_attributes = [
        :name, :stakeholder_type, :contact_person, :email, :phone, 
        :address, :notes, :specialization, :is_active, :role, 
        :company_name, :siret, :is_primary
      ]
      
      expect(policy.permitted_attributes).to eq(expected_attributes)
    end
    
    context 'with different user types' do
      it 'returns the same attributes for project manager' do
        policy = described_class.new(project_manager, stakeholder_with_manager)
        expect(policy.permitted_attributes).to include(:name, :stakeholder_type, :contact_person)
      end
      
      it 'returns the same attributes for stakeholder manager' do
        stakeholder_manager = create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:stakeholders:manage' => true }
        )
        policy = described_class.new(stakeholder_manager, stakeholder)
        expect(policy.permitted_attributes).to include(:name, :stakeholder_type, :contact_person)
      end
    end
  end
end