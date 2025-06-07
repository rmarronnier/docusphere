require 'rails_helper'

RSpec.describe Immo::Promo::StakeholderPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:other_user) { create(:user, organization: create(:organization)) }
  
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
  
  subject { described_class }
  
  permissions :show? do
    it 'allows users with read permission on project' do
      create(:authorization, authorizable: project, user: user, permission_type: 'read')
      expect(subject).to permit(user, stakeholder)
    end
    
    it 'allows project manager' do
      expect(subject).to permit(user, stakeholder)
    end
    
    it 'allows admin' do
      expect(subject).to permit(admin, stakeholder)
    end
    
    it 'denies users from other organizations' do
      expect(subject).not_to permit(other_user, stakeholder)
    end
  end
  
  permissions :create?, :update?, :destroy? do
    it 'allows project manager' do
      expect(subject).to permit(user, stakeholder)
    end
    
    it 'allows users with specific permission' do
      authorized_user = create(:user, organization: organization)
      allow(authorized_user).to receive(:has_permission?).with('immo_promo:stakeholders:manage').and_return(true)
      allow(authorized_user).to receive(:has_permission?).with('immo_promo:projects:write').and_return(true)
      expect(subject).to permit(authorized_user, stakeholder)
    end
    
    it 'allows admin' do
      expect(subject).to permit(admin, stakeholder)
    end
    
    it 'denies users with only read permission' do
      reader = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: reader, permission_type: 'read')
      expect(subject).not_to permit(reader, stakeholder)
    end
  end
  
  permissions :manage_contracts? do
    it 'allows project manager' do
      expect(subject).to permit(user, stakeholder)
    end
    
    it 'allows users with contracts permission' do
      authorized_user = create(:user, organization: organization)
      allow(authorized_user).to receive(:has_permission?).with('immo_promo:contracts:manage').and_return(true)
      expect(subject).to permit(authorized_user, stakeholder)
    end
    
    it 'denies regular users' do
      regular_user = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: regular_user, permission_type: 'write')
      expect(subject).not_to permit(regular_user, stakeholder)
    end
  end
  
  permissions :manage_certifications? do
    it 'allows project manager' do
      expect(subject).to permit(user, stakeholder)
    end
    
    it 'allows users with legal permission' do
      authorized_user = create(:user, organization: organization)
      allow(authorized_user).to receive(:has_permission?).with('immo_promo:legal:manage').and_return(true)
      allow(authorized_user).to receive(:has_permission?).with('immo_promo:projects:write').and_return(true)
      expect(subject).to permit(authorized_user, stakeholder)
    end
    
    it 'denies regular users' do
      regular_user = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: regular_user, permission_type: 'write')
      expect(subject).not_to permit(regular_user, stakeholder)
    end
  end
  
  describe 'Scope' do
    let!(:project1) { create(:immo_promo_project, organization: organization) }
    let!(:project2) { create(:immo_promo_project, organization: organization) }
    let!(:project3) { create(:immo_promo_project, organization: create(:organization)) }
    
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project1) }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project2) }
    let!(:stakeholder3) { create(:immo_promo_stakeholder, project: project3) }
    
    it 'includes stakeholders from projects with read permission' do
      create(:authorization, authorizable: project1, user: user, permission_type: 'read')
      scope = Pundit.policy_scope!(user, Immo::Promo::Stakeholder)
      expect(scope).to include(stakeholder1)
      expect(scope).not_to include(stakeholder2, stakeholder3)
    end
    
    it 'includes all stakeholders in organization for admin' do
      scope = Pundit.policy_scope!(admin, Immo::Promo::Stakeholder)
      expect(scope).to include(stakeholder1, stakeholder2)
      expect(scope).not_to include(stakeholder3)
    end
  end
end