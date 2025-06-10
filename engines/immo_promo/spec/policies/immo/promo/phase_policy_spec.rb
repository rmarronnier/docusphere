require 'rails_helper'

RSpec.describe Immo::Promo::PhasePolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:phase) { create(:immo_promo_phase, project: project) }
  
  let(:admin_user) { create(:user, role: 'admin', organization: organization) }
  let(:project_manager) { create(:user, role: 'user', organization: organization) }
  let(:regular_user) { create(:user, role: 'user', organization: organization) }
  let(:external_user) { create(:user, role: 'user', organization: create(:organization)) }
  
  let(:project_with_manager) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }
  let(:phase_with_manager) { create(:immo_promo_phase, project: project_with_manager) }

  describe 'index?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, phase) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, phase_with_manager) }
      it { is_expected.to permit_action(:index) }
    end
    
    context 'with external user' do
      subject { described_class.new(external_user, phase) }
      it { is_expected.not_to permit_action(:index) }
    end
  end

  describe 'show?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, phase) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, phase_with_manager) }
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
      subject { described_class.new(regular_user, phase) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with external user' do
      subject { described_class.new(external_user, phase) }
      it { is_expected.not_to permit_action(:show) }
    end
  end

  describe 'create?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, phase) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, phase_with_manager) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, phase) }
      it { is_expected.not_to permit_action(:create) }
    end
  end

  describe 'update?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, phase) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, phase_with_manager) }
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
      subject { described_class.new(regular_user, phase) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, phase) }
      it { is_expected.not_to permit_action(:update) }
    end
  end

  describe 'destroy?' do
    context 'with admin user' do
      subject { described_class.new(admin_user, phase) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with project manager' do
      subject { described_class.new(project_manager, phase_with_manager) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with regular user' do
      subject { described_class.new(regular_user, phase) }
      it { is_expected.not_to permit_action(:destroy) }
    end
  end

  describe '#permitted_attributes' do
    let(:policy) { described_class.new(admin_user, phase) }
    
    it 'returns the expected attributes' do
      expected_attributes = [
        :name, :description, :phase_type, :position, :status, 
        :start_date, :end_date, :budget_cents, :is_critical, 
        :workflow_status, deliverables: []
      ]
      
      expect(policy.permitted_attributes).to eq(expected_attributes)
    end
    
    context 'with different user types' do
      it 'returns the same attributes for project manager' do
        policy = described_class.new(project_manager, phase_with_manager)
        expect(policy.permitted_attributes).to include(:name, :description, :phase_type)
      end
      
      it 'returns the same attributes for regular user' do
        policy = described_class.new(regular_user, phase)
        expect(policy.permitted_attributes).to include(:name, :description, :phase_type)
      end
    end
  end
end