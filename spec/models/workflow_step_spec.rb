require 'rails_helper'

RSpec.describe WorkflowStep, type: :model do
  let(:workflow) { create(:workflow) }
  
  describe 'associations' do
    it { should belong_to(:workflow) }
    it { should belong_to(:assignee).class_name('User').optional }
    it { should have_many(:workflow_submissions) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:workflow) }
    it { should validate_presence_of(:step_type) }
    it { should validate_presence_of(:position) }
    
    it 'validates step_type inclusion' do
      should validate_inclusion_of(:step_type).in_array(%w[manual automatic conditional parallel])
    end

    it 'validates position uniqueness scoped to workflow' do
      create(:workflow_step, position: 1, workflow: workflow)
      should validate_uniqueness_of(:position).scoped_to(:workflow_id)
    end
  end

  describe 'scopes' do
    let!(:step1) { create(:workflow_step, position: 1, workflow: workflow) }
    let!(:step3) { create(:workflow_step, position: 3, workflow: workflow) }
    let!(:step2) { create(:workflow_step, position: 2, workflow: workflow) }

    describe '.ordered' do
      it 'returns steps ordered by position' do
        expect(WorkflowStep.ordered).to eq([step1, step2, step3])
      end
    end

    describe '.manual' do
      let!(:manual_step) { create(:workflow_step, step_type: 'manual', workflow: workflow) }
      let!(:automatic_step) { create(:workflow_step, step_type: 'automatic', workflow: workflow) }

      it 'returns only manual steps' do
        expect(WorkflowStep.manual).to include(manual_step)
        expect(WorkflowStep.manual).not_to include(automatic_step)
      end
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
      let(:assigned_step) { create(:workflow_step, assignee: user, workflow: workflow) }
      let(:unassigned_step) { create(:workflow_step, assignee: nil, workflow: workflow) }
      
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