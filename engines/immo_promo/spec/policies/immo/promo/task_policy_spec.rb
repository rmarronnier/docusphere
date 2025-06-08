require 'rails_helper'

RSpec.describe Immo::Promo::TaskPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:phase) { create(:immo_promo_phase, project: project) }
  let(:task) { create(:immo_promo_task, phase: phase) }
  
  let(:admin_user) { create(:user, role: 'admin', organization: organization) }
  let(:project_manager) { create(:user, role: 'user', organization: organization) }
  let(:task_assignee) { create(:user, role: 'user', organization: organization) }
  let(:regular_user) { create(:user, role: 'user', organization: organization) }
  let(:external_user) { create(:user, role: 'user', organization: create(:organization)) }
  
  let(:project_with_manager) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }
  let(:phase_with_manager) { create(:immo_promo_phase, project: project_with_manager) }
  let(:task_with_manager) { create(:immo_promo_task, phase: phase_with_manager) }
  let(:assigned_task) { create(:immo_promo_task, phase: phase, assigned_to: task_assignee) }

  describe 'index?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, task) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, task_with_manager) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with task assignee' do
      subject { described_class.new(task_assignee, assigned_task) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with external user' do
      subject { described_class.new(external_user, task) }
      it { is_expected.not_to permit_action(:index) }
    end
  end

  describe 'show?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, task) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, task_with_manager) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with task assignee' do
      subject { described_class.new(task_assignee, assigned_task) }
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
      subject { described_class.new(regular_user, task) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with external user' do
      subject { described_class.new(external_user, task) }
      it { is_expected.not_to permit_action(:show) }
    end
  end

  describe 'create?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, task) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, task_with_manager) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with user having write permission on project' do
      before do
        create(:authorization,
          authorizable: project,
          user: regular_user,
          permission_level: 'write'
        )
      end
      subject { described_class.new(regular_user, task) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, task) }
      it { is_expected.not_to permit_action(:create) }
    end
  end

  describe 'update?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, task) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, task_with_manager) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with task assignee' do
      subject { described_class.new(task_assignee, assigned_task) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with user having write permission on project' do
      before do
        create(:authorization,
          authorizable: project,
          user: regular_user,
          permission_level: 'write'
        )
      end
      subject { described_class.new(regular_user, task) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, task) }
      it { is_expected.not_to permit_action(:update) }
    end
  end

  describe 'destroy?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, task) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, task_with_manager) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, task) }
      it { is_expected.not_to permit_action(:destroy) }
    end
  end

  describe 'assign?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, task) }
      it { is_expected.to permit_action(:assign) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, task_with_manager) }
      it { is_expected.to permit_action(:assign) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, task) }
      it { is_expected.not_to permit_action(:assign) }
    end
  end

  describe 'complete?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, task) }
      it { is_expected.to permit_action(:complete) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, task_with_manager) }
      it { is_expected.to permit_action(:complete) }
    end
    
    context 'with task assignee' do
      subject { described_class.new(task_assignee, assigned_task) }
      it { is_expected.to permit_action(:complete) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, task) }
      it { is_expected.not_to permit_action(:complete) }
    end
  end
end