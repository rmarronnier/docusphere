require 'rails_helper'

RSpec.describe Immo::Promo::PhaseDependency, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:predecessor_phase) { create(:immo_promo_phase, project: project) }
  let(:successor_phase) { create(:immo_promo_phase, project: project) }
  let(:phase_dependency) { create(:immo_promo_phase_dependency, predecessor_phase: predecessor_phase, successor_phase: successor_phase) }

  describe 'associations' do
    it { is_expected.to belong_to(:predecessor_phase).class_name('Immo::Promo::Phase') }
    it { is_expected.to belong_to(:successor_phase).class_name('Immo::Promo::Phase') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:dependency_type) }
    
    it 'validates phases are different' do
      dependency = build(:immo_promo_phase_dependency, predecessor_phase: predecessor_phase, successor_phase: predecessor_phase)
      expect(dependency).not_to be_valid
    end
  end

  describe 'enums' do
    it 'defines dependency_type enum' do
      expect(phase_dependency).to respond_to(:dependency_type)
    end
  end
end