require 'rails_helper'

RSpec.describe Immo::Promo::WorkflowStates do
  let(:dummy_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include Immo::Promo::WorkflowStates
      
      attribute :status, :string
      attribute :workflow_status, :string
      
      def self.name
        'DummyWorkflowModel'
      end
    end
  end
  
  let(:instance) { dummy_class.new }
  
  describe 'workflow states' do
    it 'defines workflow states' do
      expect(dummy_class.workflow_states).to include(
        'draft',
        'pending_approval',
        'approved',
        'in_progress',
        'completed',
        'cancelled',
        'on_hold'
      )
    end
  end
  
  describe 'state transitions' do
    context 'from draft state' do
      before { instance.workflow_status = 'draft' }
      
      it 'can transition to pending_approval' do
        expect(instance.can_transition_to?('pending_approval')).to be true
      end
      
      it 'cannot transition directly to completed' do
        expect(instance.can_transition_to?('completed')).to be false
      end
    end
    
    context 'from pending_approval state' do
      before { instance.workflow_status = 'pending_approval' }
      
      it 'can transition to approved or cancelled' do
        expect(instance.can_transition_to?('approved')).to be true
        expect(instance.can_transition_to?('cancelled')).to be true
      end
      
      it 'cannot transition back to draft' do
        expect(instance.can_transition_to?('draft')).to be false
      end
    end
  end
  
  describe '#transition_to!' do
    it 'transitions to valid state' do
      instance.workflow_status = 'draft'
      
      expect(instance.transition_to!('pending_approval')).to be true
      expect(instance.workflow_status).to eq('pending_approval')
    end
    
    it 'raises error for invalid transition' do
      instance.workflow_status = 'completed'
      
      expect {
        instance.transition_to!('draft')
      }.to raise_error(Immo::Promo::InvalidTransition)
    end
  end
  
  describe '#available_transitions' do
    it 'returns valid next states' do
      instance.workflow_status = 'approved'
      
      transitions = instance.available_transitions
      expect(transitions).to include('in_progress', 'cancelled')
      expect(transitions).not_to include('draft', 'pending_approval')
    end
  end
  
  describe 'state query methods' do
    it 'provides state check methods' do
      instance.workflow_status = 'in_progress'
      
      expect(instance.in_progress?).to be true
      expect(instance.completed?).to be false
      expect(instance.draft?).to be false
    end
  end
  
  describe 'scopes' do
    let(:model_class) do
      Class.new(ApplicationRecord) do
        self.table_name = 'immo_promo_projects'
        include Immo::Promo::WorkflowStates
      end
    end
    
    it 'provides workflow state scopes' do
      expect(model_class).to respond_to(:in_draft)
      expect(model_class).to respond_to(:pending_approval)
      expect(model_class).to respond_to(:approved)
      expect(model_class).to respond_to(:in_progress)
      expect(model_class).to respond_to(:completed)
    end
  end
  
  describe 'callbacks' do
    it 'triggers callbacks on state transition' do
      allow(instance).to receive(:after_approve)
      
      instance.workflow_status = 'pending_approval'
      instance.transition_to!('approved')
      
      expect(instance).to have_received(:after_approve)
    end
  end
  
  describe '#workflow_history' do
    it 'tracks state transitions' do
      instance.workflow_status = 'draft'
      instance.transition_to!('pending_approval')
      instance.transition_to!('approved')
      
      history = instance.workflow_history
      expect(history.size).to eq(2)
      expect(history.last[:from]).to eq('pending_approval')
      expect(history.last[:to]).to eq('approved')
    end
  end
end