require 'rails_helper'

RSpec.describe WorkflowManageable, type: :concern do
  # Create a test class to include the concern
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'workflows'
      include WorkflowManageable
      
      def self.name
        'TestWorkflowManageable'
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:workflow_instance) { create(:workflow, organization: organization, status: 'pending') }

  describe 'included module behavior' do
    it 'adds workflow associations' do
      expect(workflow_instance).to respond_to(:workflow_steps)
      expect(workflow_instance).to respond_to(:workflow_transitions)
    end

    it 'adds workflow methods' do
      expect(workflow_instance).to respond_to(:next_steps)
      expect(workflow_instance).to respond_to(:current_step)
      expect(workflow_instance).to respond_to(:completed_steps)
      expect(workflow_instance).to respond_to(:progress_percentage)
      expect(workflow_instance).to respond_to(:can_transition_to?)
      expect(workflow_instance).to respond_to(:transition_to!)
    end

    it 'validates status presence' do
      workflow_instance.status = nil
      expect(workflow_instance).not_to be_valid
      expect(workflow_instance.errors[:status]).to include("can't be blank")
    end

    it 'adds status scopes to the class' do
      expect(Workflow).to respond_to(:with_status)
      expect(Workflow).to respond_to(:pending)
      expect(Workflow).to respond_to(:in_progress)
      expect(Workflow).to respond_to(:completed)
      expect(Workflow).to respond_to(:cancelled)
    end
  end

  describe '#next_steps' do
    it 'returns pending steps ordered by position' do
      step1 = create(:project_workflow_step, workflowable: workflow_instance, status: 'pending', position: 2)
      step2 = create(:project_workflow_step, workflowable: workflow_instance, status: 'pending', position: 1)
      step3 = create(:project_workflow_step, workflowable: workflow_instance, status: 'completed', position: 3)
      
      next_steps = workflow_instance.next_steps
      expect(next_steps).to eq([step2, step1])
      expect(next_steps).not_to include(step3)
    end
  end

  describe '#current_step' do
    it 'returns the step with in_progress status' do
      step1 = create(:project_workflow_step, workflowable: workflow_instance, status: 'pending')
      step2 = create(:project_workflow_step, workflowable: workflow_instance, status: 'in_progress')
      step3 = create(:project_workflow_step, workflowable: workflow_instance, status: 'completed')
      
      expect(workflow_instance.current_step).to eq(step2)
    end

    it 'returns nil when no step is in progress' do
      create(:project_workflow_step, workflowable: workflow_instance, status: 'pending')
      expect(workflow_instance.current_step).to be_nil
    end
  end

  describe '#completed_steps' do
    it 'returns completed steps ordered by position' do
      step1 = create(:project_workflow_step, workflowable: workflow_instance, status: 'completed', position: 2)
      step2 = create(:project_workflow_step, workflowable: workflow_instance, status: 'completed', position: 1)
      step3 = create(:project_workflow_step, workflowable: workflow_instance, status: 'pending', position: 3)
      
      completed_steps = workflow_instance.completed_steps
      expect(completed_steps).to eq([step2, step1])
      expect(completed_steps).not_to include(step3)
    end
  end

  describe '#progress_percentage' do
    it 'calculates completion percentage' do
      create(:project_workflow_step, workflowable: workflow_instance, status: 'completed')
      create(:project_workflow_step, workflowable: workflow_instance, status: 'completed')
      create(:project_workflow_step, workflowable: workflow_instance, status: 'pending')
      create(:project_workflow_step, workflowable: workflow_instance, status: 'in_progress')
      
      expect(workflow_instance.progress_percentage).to eq(50.0)
    end

    it 'returns 0 when no steps exist' do
      expect(workflow_instance.progress_percentage).to eq(0)
    end

    it 'returns 100 when all steps are completed' do
      create(:project_workflow_step, workflowable: workflow_instance, status: 'completed')
      create(:project_workflow_step, workflowable: workflow_instance, status: 'completed')
      
      expect(workflow_instance.progress_percentage).to eq(100.0)
    end
  end

  describe '#can_transition_to?' do
    context 'when status is pending' do
      before { workflow_instance.update!(status: 'pending') }

      it 'allows transition to in_progress' do
        expect(workflow_instance.can_transition_to?('in_progress')).to be true
      end

      it 'allows transition to cancelled' do
        expect(workflow_instance.can_transition_to?('cancelled')).to be true
      end

      it 'does not allow transition to completed' do
        expect(workflow_instance.can_transition_to?('completed')).to be false
      end
    end

    context 'when status is in_progress' do
      before { workflow_instance.update!(status: 'in_progress') }

      it 'allows transition to completed' do
        expect(workflow_instance.can_transition_to?('completed')).to be true
      end

      it 'allows transition to cancelled' do
        expect(workflow_instance.can_transition_to?('cancelled')).to be true
      end

      it 'does not allow transition to pending' do
        expect(workflow_instance.can_transition_to?('pending')).to be false
      end
    end

    context 'when status is completed' do
      before { workflow_instance.update!(status: 'completed') }

      it 'does not allow any transitions' do
        expect(workflow_instance.can_transition_to?('pending')).to be false
        expect(workflow_instance.can_transition_to?('in_progress')).to be false
        expect(workflow_instance.can_transition_to?('cancelled')).to be false
      end
    end

    context 'when status is cancelled' do
      before { workflow_instance.update!(status: 'cancelled') }

      it 'allows transition to pending' do
        expect(workflow_instance.can_transition_to?('pending')).to be true
      end

      it 'allows transition to in_progress' do
        expect(workflow_instance.can_transition_to?('in_progress')).to be true
      end

      it 'does not allow transition to completed' do
        expect(workflow_instance.can_transition_to?('completed')).to be false
      end
    end
  end

  describe '#transition_to!' do
    it 'successfully transitions when allowed' do
      workflow_instance.update!(status: 'pending')
      
      result = workflow_instance.transition_to!('in_progress', user: user, comment: 'Starting work')
      
      expect(result).to be true
      expect(workflow_instance.status).to eq('in_progress')
      
      transition = workflow_instance.workflow_transitions.last
      expect(transition.from_status).to eq('pending')
      expect(transition.to_status).to eq('in_progress')
      expect(transition.user).to eq(user)
      expect(transition.comment).to eq('Starting work')
      expect(transition.transitioned_at).to be_present
    end

    it 'fails when transition is not allowed' do
      workflow_instance.update!(status: 'completed')
      
      result = workflow_instance.transition_to!('pending', user: user)
      
      expect(result).to be false
      expect(workflow_instance.status).to eq('completed')
      expect(workflow_instance.workflow_transitions).to be_empty
    end

    it 'calls transition callback methods when they exist' do
      workflow_instance.update!(status: 'pending')
      
      expect(workflow_instance).to receive(:on_transition_to_in_progress).and_call_original
      workflow_instance.transition_to!('in_progress')
    end

    it 'handles exceptions and adds errors' do
      workflow_instance.update!(status: 'pending')
      
      # Simulate an error during update
      allow(workflow_instance).to receive(:update!).and_raise(StandardError.new('Database error'))
      
      result = workflow_instance.transition_to!('in_progress')
      
      expect(result).to be false
      expect(workflow_instance.errors[:status]).to include('Impossible de changer le statut: Database error')
    end
  end

  describe '#add_step' do
    it 'creates a new workflow step' do
      expect {
        workflow_instance.add_step(
          'Review Document',
          description: 'Review the uploaded document',
          assigned_to: user
        )
      }.to change { workflow_instance.workflow_steps.count }.by(1)
      
      step = workflow_instance.workflow_steps.last
      expect(step.name).to eq('Review Document')
      expect(step.description).to eq('Review the uploaded document')
      expect(step.assigned_to).to eq(user)
      expect(step.status).to eq('pending')
    end

    it 'sets position automatically when not provided' do
      workflow_instance.add_step('Step 1')
      workflow_instance.add_step('Step 2')
      
      steps = workflow_instance.workflow_steps.order(:position)
      expect(steps.first.position).to eq(1)
      expect(steps.last.position).to eq(2)
    end

    it 'uses provided position' do
      workflow_instance.add_step('Step 1', position: 5)
      step = workflow_instance.workflow_steps.last
      expect(step.position).to eq(5)
    end
  end

  describe '#complete_step' do
    let!(:step1) { create(:project_workflow_step, workflowable: workflow_instance, status: 'pending') }
    let!(:step2) { create(:project_workflow_step, workflowable: workflow_instance, status: 'pending') }

    it 'completes the specified step' do
      expect(step1).to receive(:complete!).with(user: user, comment: 'Done')
      workflow_instance.complete_step(step1.id, user: user, comment: 'Done')
    end

    it 'transitions workflow to completed when all steps are done' do
      # Mark all other steps as completed first
      step1.update!(status: 'completed')
      allow(step2).to receive(:complete!).and_return(true)
      step2.update!(status: 'completed')
      
      # Mock the workflow_steps relation to return no pending steps
      allow(workflow_instance.workflow_steps).to receive(:where).and_return(double(empty?: true))
      
      expect(workflow_instance).to receive(:transition_to!).with('completed', user: user, comment: 'Toutes les étapes sont terminées')
      
      workflow_instance.complete_step(step2.id, user: user)
    end

    it 'does not transition workflow when steps remain' do
      allow(step1).to receive(:complete!).and_return(true)
      
      expect(workflow_instance).not_to receive(:transition_to!)
      
      workflow_instance.complete_step(step1.id, user: user)
    end
  end

  describe 'transition callback methods' do
    it 'defines callback methods that can be overridden' do
      expect(workflow_instance).to respond_to(:on_transition_to_in_progress, true)
      expect(workflow_instance).to respond_to(:on_transition_to_completed, true)
      expect(workflow_instance).to respond_to(:on_transition_to_cancelled, true)
    end

    it 'calls the appropriate callback method during transition' do
      workflow_instance.update!(status: 'pending')
      
      # Define a custom callback
      def workflow_instance.on_transition_to_in_progress
        @callback_called = true
      end
      
      workflow_instance.transition_to!('in_progress')
      
      expect(workflow_instance.instance_variable_get(:@callback_called)).to be true
    end
  end

  describe 'scopes' do
    let!(:pending_workflow) { create(:workflow, organization: organization, status: 'pending') }
    let!(:in_progress_workflow) { create(:workflow, organization: organization, status: 'in_progress') }
    let!(:completed_workflow) { create(:workflow, organization: organization, status: 'completed') }
    let!(:cancelled_workflow) { create(:workflow, organization: organization, status: 'cancelled') }

    describe '.with_status' do
      it 'filters by specific status' do
        pending_workflows = Workflow.with_status('pending')
        expect(pending_workflows).to include(pending_workflow)
        expect(pending_workflows).not_to include(in_progress_workflow, completed_workflow, cancelled_workflow)
      end
    end

    describe '.pending' do
      it 'returns workflows with pending status' do
        pending_workflows = Workflow.pending
        expect(pending_workflows).to include(pending_workflow)
        expect(pending_workflows).not_to include(in_progress_workflow, completed_workflow, cancelled_workflow)
      end
    end

    describe '.in_progress' do
      it 'returns workflows with in_progress status' do
        in_progress_workflows = Workflow.in_progress
        expect(in_progress_workflows).to include(in_progress_workflow)
        expect(in_progress_workflows).not_to include(pending_workflow, completed_workflow, cancelled_workflow)
      end
    end

    describe '.completed' do
      it 'returns workflows with completed status' do
        completed_workflows = Workflow.completed
        expect(completed_workflows).to include(completed_workflow)
        expect(completed_workflows).not_to include(pending_workflow, in_progress_workflow, cancelled_workflow)
      end
    end

    describe '.cancelled' do
      it 'returns workflows with cancelled status' do
        cancelled_workflows = Workflow.cancelled
        expect(cancelled_workflows).to include(cancelled_workflow)
        expect(cancelled_workflows).not_to include(pending_workflow, in_progress_workflow, completed_workflow)
      end
    end
  end
end