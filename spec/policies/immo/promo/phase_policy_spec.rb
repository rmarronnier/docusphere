require 'rails_helper'

RSpec.describe Immo::Promo::PhasePolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:super_admin) { create(:user, :super_admin, organization: organization) }
  let(:other_user) { create(:user, organization: create(:organization)) }
  
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:phase) { create(:immo_promo_phase, project: project) }
  
  permissions :show? do
    it 'allows users with read permission on project' do
      create(:authorization, authorizable: project, user: user, permission_type: 'read')
      expect(described_class).to permit(user, phase)
    end
    
    it 'allows project manager' do
      expect(described_class).to permit(user, phase)
    end
    
    it 'allows admin' do
      expect(described_class).to permit(admin, phase)
    end
    
    it 'denies users from other organizations' do
      expect(described_class).not_to permit(other_user, phase)
    end
  end
  
  permissions :create?, :update? do
    it 'allows project manager' do
      expect(described_class).to permit(user, phase)
    end
    
    it 'allows users with write permission on project' do
      writer = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: writer, permission_type: 'write')
      expect(described_class).to permit(writer, phase)
    end
    
    it 'allows admin' do
      expect(described_class).to permit(admin, phase)
    end
    
    it 'denies users with only read permission' do
      reader = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: reader, permission_type: 'read')
      expect(described_class).not_to permit(reader, phase)
    end
  end
  
  permissions :destroy? do
    it 'allows project manager' do
      expect(described_class).to permit(user, phase)
    end
    
    it 'allows admin' do
      expect(described_class).to permit(admin, phase)
    end
    
    it 'denies other users even with write permission' do
      writer = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: writer, permission_type: 'write')
      expect(described_class).not_to permit(writer, phase)
    end
  end
  
  permissions :complete? do
    it 'allows project manager' do
      expect(described_class).to permit(user, phase)
    end
    
    it 'allows users with write permission' do
      writer = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: writer, permission_type: 'write')
      expect(described_class).to permit(writer, phase)
    end
    
    it 'denies users with only read permission' do
      reader = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: reader, permission_type: 'read')
      expect(described_class).not_to permit(reader, phase)
    end
  end
  
  describe 'Scope' do
    let!(:project1) { create(:immo_promo_project, organization: organization) }
    let!(:project2) { create(:immo_promo_project, organization: organization) }
    let!(:project3) { create(:immo_promo_project, organization: create(:organization)) }
    
    let!(:phase1) { create(:immo_promo_phase, project: project1) }
    let!(:phase2) { create(:immo_promo_phase, project: project2) }
    let!(:phase3) { create(:immo_promo_phase, project: project3) }
    
    it 'includes phases from projects with read permission' do
      create(:authorization, authorizable: project1, user: user, permission_type: 'read')
      scope = Pundit.policy_scope!(user, Immo::Promo::Phase)
      expect(scope).to include(phase1)
      expect(scope).not_to include(phase2, phase3)
    end
    
    it 'includes all phases for admin' do
      scope = Pundit.policy_scope!(admin, Immo::Promo::Phase)
      expect(scope).to include(phase1, phase2)
      expect(scope).not_to include(phase3)
    end
    
    it 'includes all phases for super admin' do
      scope = Pundit.policy_scope!(super_admin, Immo::Promo::Phase)
      expect(scope).to include(phase1, phase2, phase3)
    end
  end
end