require 'rails_helper'

RSpec.describe Workflow, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should have_many(:workflow_steps).dependent(:destroy) }
    it { should have_many(:workflow_submissions).dependent(:destroy) }
    # Workflow submissions are not directly linked to documents
  end

  describe 'validations' do
    subject { build(:workflow) }
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
  end

  describe 'state machine' do
    let(:workflow) { create(:workflow) }

    it 'starts in draft state' do
      expect(workflow.status).to eq('draft')
      expect(workflow).to be_draft
    end

    describe 'transitions' do
      it 'can transition from draft to active' do
        expect { workflow.activate! }.to change { workflow.status }.from('draft').to('active')
      end

      it 'can transition from active to paused' do
        workflow.activate!
        expect { workflow.pause! }.to change { workflow.status }.from('active').to('paused')
      end

      it 'can transition from paused to active' do
        workflow.activate!
        workflow.pause!
        expect { workflow.resume! }.to change { workflow.status }.from('paused').to('active')
      end

      it 'can transition from active to completed' do
        workflow.activate!
        expect { workflow.complete! }.to change { workflow.status }.from('active').to('completed')
      end

      it 'can transition to cancelled from any state' do
        expect { workflow.cancel! }.to change { workflow.status }.to('cancelled')
      end
    end
  end

  describe 'factory' do
    it 'creates a valid workflow' do
      workflow = create(:workflow)
      expect(workflow).to be_valid
    end

    describe 'with_steps trait' do
      let(:workflow) { create(:workflow, :with_steps) }
      
      it 'creates a workflow with steps' do
        expect(workflow.workflow_steps.count).to eq(3)
      end
    end

    describe 'status traits' do
      it 'creates active workflows' do
        workflow = create(:workflow, :active)
        expect(workflow).to be_active
      end
      
      it 'creates completed workflows' do
        workflow = create(:workflow, :completed)
        expect(workflow).to be_completed
      end
      
      it 'creates cancelled workflows' do
        workflow = create(:workflow, :cancelled)
        expect(workflow).to be_cancelled
      end
    end
  end

  describe 'workflow management' do
    let(:workflow) { create(:workflow, :with_steps) }
    
    describe '#progress_percentage' do
      it 'calculates progress based on completed steps' do
        expect(workflow.progress_percentage).to be_a(Numeric)
        expect(workflow.progress_percentage).to be >= 0
        expect(workflow.progress_percentage).to be <= 100
      end
    end

    describe '#can_be_activated?' do
      it 'returns true for draft workflows with steps' do
        expect(workflow.can_be_activated?).to be true
      end
      
      it 'returns false for workflows without steps' do
        empty_workflow = create(:workflow)
        expect(empty_workflow.can_be_activated?).to be false
      end
    end
  end
end