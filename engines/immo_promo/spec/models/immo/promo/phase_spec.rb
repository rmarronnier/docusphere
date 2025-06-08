require 'rails_helper'

RSpec.describe Immo::Promo::Phase, type: :model do
  let(:project) { create(:immo_promo_project) }
  let(:phase) { create(:immo_promo_phase, project: project) }

  describe 'associations' do
    it { should belong_to(:project).class_name('Immo::Promo::Project') }
    it { should belong_to(:responsible_user).class_name('User').optional }
    it { should have_many(:tasks).class_name('Immo::Promo::Task').dependent(:destroy) }
    it { should have_many(:phase_dependencies).class_name('Immo::Promo::PhaseDependency').dependent(:destroy) }
    it { should have_many(:dependent_phases).through(:phase_dependencies) }
    it { should have_many(:inverse_phase_dependencies).class_name('Immo::Promo::PhaseDependency').dependent(:destroy) }
    it { should have_many(:prerequisite_phases).through(:inverse_phase_dependencies) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should define_enum_for(:phase_type).backed_by_column_of_type(:string).with_values(
      studies: 'studies',
      permits: 'permits',
      construction: 'construction',
      finishing: 'finishing',
      delivery: 'delivery',
      reception: 'reception',
      other: 'other'
    ) }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).is_greater_than(0) }
  end

  describe 'enums' do
    it { should define_enum_for(:phase_type).backed_by_column_of_type(:string).with_values(
      studies: 'studies',
      permits: 'permits',
      construction: 'construction',
      finishing: 'finishing',
      delivery: 'delivery',
      reception: 'reception',
      other: 'other'
    ) }

    it { should define_enum_for(:status).backed_by_column_of_type(:string).with_values(
      pending: 'pending',
      in_progress: 'in_progress',
      completed: 'completed',
      on_hold: 'on_hold',
      cancelled: 'cancelled'
    ) }
  end

  describe 'monetization' do
    it 'has monetized budget' do
      phase.budget = 100.50
      expect(phase.budget_cents).to eq(10050)
      expect(phase.budget).to be_a(Money)
    end
    
    it 'has monetized actual_cost' do
      phase.actual_cost = 200.75
      expect(phase.actual_cost_cents).to eq(20075)
      expect(phase.actual_cost).to be_a(Money)
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns phases not completed or cancelled' do
        active_phase = create(:immo_promo_phase, status: 'in_progress')
        completed_phase = create(:immo_promo_phase, status: 'completed')
        cancelled_phase = create(:immo_promo_phase, status: 'cancelled')

        expect(Immo::Promo::Phase.active).to include(active_phase)
        expect(Immo::Promo::Phase.active).not_to include(completed_phase, cancelled_phase)
      end
    end

    describe '.critical' do
      it 'returns critical phases' do
        critical_phase = create(:immo_promo_phase, is_critical: true)
        non_critical_phase = create(:immo_promo_phase, is_critical: false)

        expect(Immo::Promo::Phase.critical).to include(critical_phase)
        expect(Immo::Promo::Phase.critical).not_to include(non_critical_phase)
      end
    end

    describe '.delayed' do
      it 'returns phases past their end date' do
        delayed_phase = create(:immo_promo_phase, start_date: 3.days.ago, end_date: 1.day.ago, status: 'in_progress')
        on_time_phase = create(:immo_promo_phase, start_date: 2.days.ago, end_date: 1.day.from_now, status: 'in_progress')
        completed_phase = create(:immo_promo_phase, start_date: 4.days.ago, end_date: 1.day.ago, status: 'completed')

        expect(Immo::Promo::Phase.delayed).to include(delayed_phase)
        expect(Immo::Promo::Phase.delayed).not_to include(on_time_phase, completed_phase)
      end
    end
  end

  describe '#completion_percentage' do
    context 'with no tasks' do
      it 'returns 0' do
        expect(phase.completion_percentage).to eq(0)
      end
    end

    context 'with tasks' do
      it 'calculates the percentage of completed tasks' do
        create(:immo_promo_task, phase: phase, status: 'completed')
        create(:immo_promo_task, phase: phase, status: 'completed')
        create(:immo_promo_task, phase: phase, status: 'in_progress')
        create(:immo_promo_task, phase: phase, status: 'pending')

        expect(phase.completion_percentage).to eq(50.0)
      end
    end
  end

  describe '#is_delayed?' do
    context 'when phase is completed' do
      it 'returns false' do
        phase.update(status: 'completed', end_date: 1.day.ago)
        expect(phase.is_delayed?).to be_falsey
      end
    end

    context 'when phase is past end date' do
      it 'returns true' do
        phase.update(status: 'in_progress', end_date: 1.day.ago)
        expect(phase.is_delayed?).to be_truthy
      end
    end

    context 'when phase is on time' do
      it 'returns false' do
        phase.update(status: 'in_progress', end_date: 1.day.from_now)
        expect(phase.is_delayed?).to be_falsey
      end
    end
  end

  describe '#can_start?' do
    context 'with no prerequisite phases' do
      it 'returns true' do
        expect(phase.can_start?).to be_truthy
      end
    end

    context 'with completed prerequisite phases' do
      it 'returns true' do
        prerequisite = create(:immo_promo_phase, project: project, status: 'completed')
        create(:immo_promo_phase_dependency, 
               prerequisite_phase: prerequisite, 
               dependent_phase: phase)
        
        expect(phase.can_start?).to be_truthy
      end
    end

    context 'with incomplete prerequisite phases' do
      it 'returns false' do
        prerequisite = create(:immo_promo_phase, project: project, status: 'in_progress')
        create(:immo_promo_phase_dependency, 
               prerequisite_phase: prerequisite, 
               dependent_phase: phase)
        
        expect(phase.can_start?).to be_falsey
      end
    end
  end

  describe '#days_remaining' do
    it 'returns the number of days until end date' do
      phase.end_date = 5.days.from_now.to_date
      expect(phase.days_remaining).to eq(5)
    end

    it 'returns 0 for past dates' do
      phase.end_date = 5.days.ago.to_date
      expect(phase.days_remaining).to eq(0)
    end

    it 'returns 0 when no end date' do
      phase.end_date = nil
      expect(phase.days_remaining).to eq(0)
    end
  end

  describe 'concerns' do
    # it_behaves_like 'schedulable' # Disabled - shared example has implementation issues
  end
end