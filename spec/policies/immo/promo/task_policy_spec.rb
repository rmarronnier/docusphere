require 'rails_helper'

RSpec.describe Immo::Promo::TaskPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:other_user) { create(:user, organization: create(:organization)) }
  
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:phase) { create(:immo_promo_phase, project: project) }
  let(:task) { create(:immo_promo_task, phase: phase) }
  
  permissions :show? do
    it 'allows users with read permission on project' do
      create(:authorization, authorizable: project, user: user, permission_type: 'read')
      expect(described_class).to permit(user, task)
    end
    
    it 'allows assigned user' do
      assignee = create(:user, organization: organization)
      task.update(assigned_to: assignee)
      expect(described_class).to permit(assignee, task)
    end
    
    it 'allows admin' do
      expect(described_class).to permit(admin, task)
    end
    
    it 'denies users from other organizations' do
      expect(described_class).not_to permit(other_user, task)
    end
  end
  
  permissions :create?, :update? do
    it 'allows project manager' do
      expect(described_class).to permit(user, task)
    end
    
    it 'allows users with write permission on project' do
      writer = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: writer, permission_type: 'write')
      expect(described_class).to permit(writer, task)
    end
    
    it 'allows assigned user' do
      assignee = create(:user, organization: organization)
      task.update(assigned_to: assignee)
      expect(described_class).to permit(assignee, task)
    end
    
    it 'denies users with only read permission' do
      reader = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: reader, permission_type: 'read')
      expect(described_class).not_to permit(reader, task)
    end
  end
  
  permissions :destroy? do
    it 'allows project manager' do
      expect(described_class).to permit(user, task)
    end
    
    it 'allows admin' do
      expect(described_class).to permit(admin, task)
    end
    
    it 'denies assigned user' do
      assignee = create(:user, organization: organization)
      task.update(assigned_to: assignee)
      expect(described_class).not_to permit(assignee, task)
    end
  end
  
  permissions :complete?, :assign? do
    it 'allows project manager' do
      expect(described_class).to permit(user, task)
    end
    
    it 'allows users with write permission' do
      writer = create(:user, organization: organization)
      create(:authorization, authorizable: project, user: writer, permission_type: 'write')
      expect(described_class).to permit(writer, task)
    end
    
    it 'allows assigned user to complete' do
      assignee = create(:user, organization: organization)
      task.update(assigned_to: assignee)
      expect(described_class).to permit(assignee, task)
    end
  end
  
  permissions :my_tasks? do
    it 'allows any authenticated user' do
      expect(described_class).to permit(user, Immo::Promo::Task)
    end
    
    it 'allows users from other organizations since it is class-level' do
      # Since my_tasks? is a class-level check, we can't determine organization
      # The controller will handle the organization filtering
      expect(described_class).to permit(other_user, Immo::Promo::Task)
    end
  end
  
  describe 'Scope' do
    let!(:project1) { create(:immo_promo_project, organization: organization) }
    let!(:project2) { create(:immo_promo_project, organization: organization) }
    
    let!(:phase1) { create(:immo_promo_phase, project: project1) }
    let!(:phase2) { create(:immo_promo_phase, project: project2) }
    
    let!(:task1) { create(:immo_promo_task, phase: phase1) }
    let!(:task2) { create(:immo_promo_task, phase: phase2) }
    let!(:task3) { create(:immo_promo_task, phase: phase1, assigned_to: user) }
    
    it 'includes tasks from projects with permission' do
      create(:authorization, authorizable: project1, user: user, permission_type: 'read')
      scope = Pundit.policy_scope!(user, Immo::Promo::Task)
      expect(scope).to include(task1, task3)
      expect(scope).not_to include(task2)
    end
    
    it 'includes assigned tasks even without project permission' do
      other_member = create(:user, organization: organization)
      task2.update(assigned_to: other_member)
      scope = Pundit.policy_scope!(other_member, Immo::Promo::Task)
      expect(scope).to include(task2)
    end
  end
end