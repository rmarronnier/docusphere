require 'rails_helper'

RSpec.describe WorkflowStep, type: :model do
  let(:workflow) { create(:workflow) }
  
  describe 'associations' do
    it { should belong_to(:workflow) }
    it { should belong_to(:assigned_to).class_name('User').optional }
    it { should belong_to(:assigned_to_group).class_name('UserGroup').optional }
    it { should belong_to(:completed_by).class_name('User').optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:position) }
  end

  describe 'AASM states' do
    let(:step) { create(:workflow_step, workflow: workflow) }

    it 'has initial state of pending' do
      expect(step).to be_pending
    end

    it 'can transition from pending to in_progress' do
      expect(step.may_start?).to be true
      expect { step.start! }.to change { step.status }.from('pending').to('in_progress')
    end

    it 'can transition from in_progress to completed' do
      step.start!
      expect(step.may_complete?).to be true
      expect { step.complete! }.to change { step.status }.from('in_progress').to('completed')
    end

    it 'sets completed_at when completed' do
      step.start!
      expect { step.complete! }.to change { step.completed_at }.from(nil)
    end
  end

  describe 'instance methods' do
    let(:step) { create(:workflow_step, workflow: workflow) }
    
    describe '#next_step' do
      let!(:step1) { create(:workflow_step, position: 1, workflow: workflow) }
      let!(:step2) { create(:workflow_step, position: 2, workflow: workflow) }
      
      it 'returns the next step in sequence' do
        expect(step1.next_step).to eq(step2)
      end

      it 'returns nil for last step' do
        expect(step2.next_step).to be_nil
      end
    end

    describe '#previous_step' do
      let!(:step1) { create(:workflow_step, position: 1, workflow: workflow) }
      let!(:step2) { create(:workflow_step, position: 2, workflow: workflow) }
      
      it 'returns the previous step in sequence' do
        expect(step2.previous_step).to eq(step1)
      end

      it 'returns nil for first step' do
        expect(step1.previous_step).to be_nil
      end
    end

    describe '#can_be_completed_by?' do
      let(:user) { create(:user) }
      let(:assigned_step) { create(:workflow_step, assigned_to: user, workflow: workflow) }
      let(:unassigned_step) { create(:workflow_step, assigned_to: nil, workflow: workflow) }
      
      it 'returns true if user is assignee' do
        expect(assigned_step.can_be_completed_by?(user)).to be true
      end

      it 'returns true if step is unassigned' do
        expect(unassigned_step.can_be_completed_by?(user)).to be true
      end

      it 'returns false if user is not assignee' do
        other_user = create(:user)
        expect(assigned_step.can_be_completed_by?(other_user)).to be false
      end
    end

    describe '#estimated_duration_in_hours' do
      it 'returns estimated duration divided by 3600' do
        step.update(estimated_duration: 7200) # 2 hours in seconds
        expect(step.estimated_duration_in_hours).to eq(2)
      end

      it 'returns 0 if no estimated duration' do
        step.update(estimated_duration: nil)
        expect(step.estimated_duration_in_hours).to eq(0)
      end
    end
  end
end