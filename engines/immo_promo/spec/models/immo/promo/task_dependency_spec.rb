require 'rails_helper'

RSpec.describe Immo::Promo::TaskDependency, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:predecessor_task) { create(:immo_promo_task, project: project) }
  let(:successor_task) { create(:immo_promo_task, project: project) }
  let(:task_dependency) { create(:immo_promo_task_dependency, predecessor_task: predecessor_task, successor_task: successor_task) }

  describe 'associations' do
    it { is_expected.to belong_to(:predecessor_task).class_name('Immo::Promo::Task') }
    it { is_expected.to belong_to(:successor_task).class_name('Immo::Promo::Task') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:dependency_type) }
    
    it 'validates tasks are different' do
      dependency = build(:immo_promo_task_dependency, predecessor_task: predecessor_task, successor_task: predecessor_task)
      expect(dependency).not_to be_valid
    end
  end

  describe 'enums' do
    it 'defines dependency_type enum' do
      expect(task_dependency).to respond_to(:dependency_type)
    end
  end
end