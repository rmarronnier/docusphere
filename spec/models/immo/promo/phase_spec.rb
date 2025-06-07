require 'rails_helper'

RSpec.describe Immo::Promo::Phase, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  
  describe 'associations' do
    it { should belong_to(:project) }
    it { should have_many(:tasks).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:immo_promo_phase, project: project) }
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:position) }
    it { should validate_uniqueness_of(:position).scoped_to(:project_id) }
  end

  describe 'concerns' do
    it 'includes Schedulable' do
      expect(described_class.included_modules).to include(Schedulable)
    end
    
    it 'includes WorkflowManageable' do
      expect(described_class.included_modules).to include(WorkflowManageable)
    end
  end

  describe 'enum' do
    it { should define_enum_for(:phase_type).backed_by_column_of_type(:string).with_values(studies: 'studies', permits: 'permits', construction: 'construction', reception: 'reception', delivery: 'delivery') }
    it { should define_enum_for(:status).backed_by_column_of_type(:string).with_values(pending: 'pending', in_progress: 'in_progress', completed: 'completed', delayed: 'delayed', cancelled: 'cancelled') }
  end

  describe 'scopes' do
    let!(:active_phase) { create(:immo_promo_phase, project: project, status: 'in_progress') }
    let!(:completed_phase) { create(:immo_promo_phase, project: project, status: 'completed') }
    let!(:studies_phase) { create(:immo_promo_phase, project: project, phase_type: 'studies', status: 'completed') }
    let!(:construction_phase) { create(:immo_promo_phase, project: project, phase_type: 'construction', status: 'cancelled') }

    describe '.active' do
      it 'returns only active phases' do
        expect(described_class.active).to contain_exactly(active_phase)
      end
    end

    describe '.by_type' do
      it 'returns phases of specified type' do
        expect(described_class.by_type('studies')).to include(studies_phase)
        expect(described_class.by_type('studies')).not_to include(construction_phase)
      end
    end
    
    describe '.ordered' do
      let(:ordered_project) { create(:immo_promo_project, organization: organization) }
      let!(:phase_3) { create(:immo_promo_phase, project: ordered_project, position: 3) }
      let!(:phase_1) { create(:immo_promo_phase, project: ordered_project, position: 1) }
      let!(:phase_2) { create(:immo_promo_phase, project: ordered_project, position: 2) }
      
      it 'returns phases ordered by position' do
        expect(ordered_project.phases.ordered).to eq([phase_1, phase_2, phase_3])
      end
    end
  end


  describe 'instance methods' do
    let(:phase) { create(:immo_promo_phase, project: project) }
    
    describe '#completion_percentage' do
      context 'with no tasks' do
        it 'returns 0' do
          expect(phase.completion_percentage).to eq(0)
        end
      end
      
      context 'with tasks' do
        before do
          create(:immo_promo_task, phase: phase, status: 'completed')
          create(:immo_promo_task, phase: phase, status: 'in_progress')
          create(:immo_promo_task, phase: phase, status: 'pending')
        end
        
        it 'calculates completion based on completed tasks' do
          expect(phase.completion_percentage).to eq(33.33)
        end
      end
    end
    
    describe '#is_delayed?' do
      context 'when end_date is in the future' do
        before { phase.update(end_date: 1.week.from_now) }
        
        it 'returns false' do
          expect(phase.is_delayed?).to be false
        end
      end
      
      context 'when end_date is in the past and not completed' do
        before { phase.update(end_date: 1.week.ago, status: 'in_progress') }
        
        it 'returns true' do
          expect(phase.is_delayed?).to be true
        end
      end
      
      context 'when completed' do
        before { phase.update(end_date: 1.week.ago, status: 'completed') }
        
        it 'returns false' do
          expect(phase.is_delayed?).to be false
        end
      end
    end
    
    describe '#can_start?' do
      context 'with no prerequisite phases' do
        it 'returns true' do
          expect(phase.can_start?).to be true
        end
      end
      
      context 'with completed prerequisite phases' do
        let(:prerequisite) { create(:immo_promo_phase, project: project, status: 'completed') }
        
        before do
          create(:immo_promo_phase_dependency, dependent_phase: phase, prerequisite_phase: prerequisite)
        end
        
        it 'returns true' do
          expect(phase.can_start?).to be true
        end
      end
      
      context 'with incomplete prerequisite phases' do
        let(:prerequisite) { create(:immo_promo_phase, project: project, status: 'pending') }
        
        before do
          create(:immo_promo_phase_dependency, dependent_phase: phase, prerequisite_phase: prerequisite)
        end
        
        it 'returns false' do
          expect(phase.can_start?).to be false
        end
      end
    end
  end
end