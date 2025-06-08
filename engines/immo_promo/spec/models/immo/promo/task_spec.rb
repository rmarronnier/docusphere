require 'rails_helper'

RSpec.describe Immo::Promo::Task, type: :model do
  let(:phase) { create(:immo_promo_phase) }
  let(:user) { create(:user) }
  let(:task) { create(:immo_promo_task, phase: phase, assigned_to: user) }

  describe 'associations' do
    it { should belong_to(:phase).class_name('Immo::Promo::Phase') }
    it { should belong_to(:assigned_to).class_name('User').optional }
    it { should belong_to(:stakeholder).class_name('Immo::Promo::Stakeholder').optional }
    it { should have_many(:time_logs).class_name('Immo::Promo::TimeLog').dependent(:destroy) }
    it { should have_many(:task_dependencies).class_name('Immo::Promo::TaskDependency').dependent(:destroy) }
    it { should have_many(:dependent_tasks).through(:task_dependencies) }
    it { should have_many(:inverse_task_dependencies).class_name('Immo::Promo::TaskDependency').dependent(:destroy) }
    it { should have_many(:prerequisite_tasks).through(:inverse_task_dependencies) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:task_type) }
    it { should validate_presence_of(:priority) }
    it { should validate_numericality_of(:estimated_hours).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'enums' do
    it { should define_enum_for(:task_type).backed_by_column_of_type(:string).with_values(
      planning: 'planning',
      execution: 'execution',
      review: 'review',
      approval: 'approval',
      milestone: 'milestone',
      administrative: 'administrative',
      technical: 'technical',
      other: 'other'
    ) }

    it { should define_enum_for(:status).backed_by_column_of_type(:string).with_values(
      pending: 'pending',
      in_progress: 'in_progress',
      completed: 'completed',
      blocked: 'blocked',
      cancelled: 'cancelled'
    ) }

    it { should define_enum_for(:priority).backed_by_column_of_type(:string).with_values(
      low: 'low',
      medium: 'medium',
      high: 'high',
      critical: 'critical'
    ) }
  end

  describe 'monetization' do
    it { should monetize(:estimated_cost) }
    it { should monetize(:actual_cost) }
  end

  describe 'scopes' do
    describe '.overdue' do
      it 'returns tasks past their due date' do
        overdue_task = create(:immo_promo_task, end_date: 1.day.ago, status: 'in_progress')
        on_time_task = create(:immo_promo_task, end_date: 1.day.from_now, status: 'in_progress')
        completed_task = create(:immo_promo_task, end_date: 1.day.ago, status: 'completed')

        expect(Immo::Promo::Task.overdue).to include(overdue_task)
        expect(Immo::Promo::Task.overdue).not_to include(on_time_task, completed_task)
      end
    end

    describe '.assigned_to_user' do
      it 'returns tasks assigned to a specific user' do
        user_task = create(:immo_promo_task, assigned_to: user)
        other_task = create(:immo_promo_task, assigned_to: create(:user))

        expect(Immo::Promo::Task.assigned_to_user(user)).to include(user_task)
        expect(Immo::Promo::Task.assigned_to_user(user)).not_to include(other_task)
      end
    end

    describe '.high_priority' do
      it 'returns high and critical priority tasks' do
        high_task = create(:immo_promo_task, priority: 'high')
        critical_task = create(:immo_promo_task, priority: 'critical')
        medium_task = create(:immo_promo_task, priority: 'medium')

        expect(Immo::Promo::Task.high_priority).to include(high_task, critical_task)
        expect(Immo::Promo::Task.high_priority).not_to include(medium_task)
      end
    end
  end

  describe '#is_overdue?' do
    context 'when task is completed' do
      it 'returns false' do
        task.update(status: 'completed', end_date: 1.day.ago)
        expect(task.is_overdue?).to be_falsey
      end
    end

    context 'when task is past end date' do
      it 'returns true' do
        task.update(status: 'in_progress', end_date: 1.day.ago)
        expect(task.is_overdue?).to be_truthy
      end
    end

    context 'when task has no end date' do
      it 'returns false' do
        task.update(end_date: nil)
        expect(task.is_overdue?).to be_falsey
      end
    end
  end

  describe '#progress_percentage' do
    context 'without estimated hours' do
      it 'returns 0' do
        task.update(estimated_hours: nil)
        expect(task.progress_percentage).to eq(0)
      end
    end

    context 'with time logs' do
      it 'calculates percentage based on logged hours' do
        task.update(estimated_hours: 10)
        create(:immo_promo_time_log, task: task, hours: 3)
        create(:immo_promo_time_log, task: task, hours: 2)

        expect(task.progress_percentage).to eq(50.0)
      end

      it 'caps at 100%' do
        task.update(estimated_hours: 10)
        create(:immo_promo_time_log, task: task, hours: 15)

        expect(task.progress_percentage).to eq(100.0)
      end
    end
  end

  describe '#logged_hours' do
    it 'returns total hours from time logs' do
      create(:immo_promo_time_log, task: task, hours: 3.5)
      create(:immo_promo_time_log, task: task, hours: 2.5)

      expect(task.logged_hours).to eq(6.0)
    end

    it 'returns 0 when no time logs' do
      expect(task.logged_hours).to eq(0)
    end
  end

  describe '#can_start?' do
    context 'with no prerequisite tasks' do
      it 'returns true' do
        expect(task.can_start?).to be_truthy
      end
    end

    context 'with completed prerequisite tasks' do
      it 'returns true' do
        prerequisite = create(:immo_promo_task, phase: phase, status: 'completed')
        create(:immo_promo_task_dependency, 
               prerequisite_task: prerequisite, 
               dependent_task: task)
        
        expect(task.can_start?).to be_truthy
      end
    end

    context 'with incomplete prerequisite tasks' do
      it 'returns false' do
        prerequisite = create(:immo_promo_task, phase: phase, status: 'in_progress')
        create(:immo_promo_task_dependency, 
               prerequisite_task: prerequisite, 
               dependent_task: task)
        
        expect(task.can_start?).to be_falsey
      end
    end
  end

  describe '#days_remaining' do
    it 'returns the number of days until end date' do
      task.end_date = 5.days.from_now.to_date
      expect(task.days_remaining).to eq(5)
    end

    it 'returns 0 for past dates' do
      task.end_date = 5.days.ago.to_date
      expect(task.days_remaining).to eq(0)
    end

    it 'returns 0 when no end date' do
      task.end_date = nil
      expect(task.days_remaining).to eq(0)
    end
  end

  describe '#completion_status' do
    it 'returns "Terminée" when completed' do
      task.update(status: 'completed')
      expect(task.completion_status).to eq('Terminée')
    end

    it 'returns "En retard" when overdue' do
      task.update(status: 'in_progress', end_date: 1.day.ago)
      expect(task.completion_status).to eq('En retard')
    end

    it 'returns percentage when in progress' do
      task.update(status: 'in_progress', estimated_hours: 10)
      create(:immo_promo_time_log, task: task, hours: 5)
      expect(task.completion_status).to eq('50%')
    end

    it 'returns "En attente" when pending' do
      task.update(status: 'pending')
      expect(task.completion_status).to eq('En attente')
    end
  end

  describe 'concerns' do
    it_behaves_like 'schedulable'
  end
end