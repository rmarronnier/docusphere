require 'rails_helper'

RSpec.describe Immo::Promo::PermitWorkflow::WorkflowManagement, type: :concern do
  
  let(:controller_class) do
    Class.new do
      include Immo::Promo::PermitWorkflow::WorkflowManagement
      
      attr_accessor :project
      
      def initialize(project = nil)
        @project = project
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_type: 'residential') }
  let(:controller) { controller_class.new(project) }

  describe '#generate_workflow_for_project_type' do
    it 'generates workflow for residential project' do
      workflow = controller.generate_workflow_for_project_type('residential')
      
      expect(workflow).to be_an(Array)
      expect(workflow.length).to be >= 3
      expect(workflow.first[:step]).to eq(1)
      expect(workflow.first[:name]).to eq('Étude de faisabilité')
    end

    it 'generates workflow for commercial project' do
      workflow = controller.generate_workflow_for_project_type('commercial')
      
      expect(workflow).to be_an(Array)
      expect(workflow.length).to be >= 4
    end

    it 'generates basic workflow for unknown type' do
      workflow = controller.generate_workflow_for_project_type('unknown')
      
      expect(workflow).to be_an(Array)
      expect(workflow.length).to eq(3)
    end
  end

  describe '#determine_current_workflow_step' do
    it 'returns 1 when no permits are approved' do
      current_step = controller.determine_current_workflow_step
      expect(current_step).to eq(1)
    end

    it 'advances step when all required permits are approved' do
      # Étape 1 requiert 'declaration'
      create(:immo_promo_permit, project: project, permit_type: 'declaration', status: 'approved')
      
      current_step = controller.determine_current_workflow_step
      expect(current_step).to eq(2) # Avance à l'étape 2
      
      # Étape 2 requiert urban_planning ET construction
      create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'approved')
      create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'approved')
      
      current_step = controller.determine_current_workflow_step
      expect(current_step).to eq(3) # Avance à l'étape 3
    end
  end

  describe '#calculate_completed_steps' do
    it 'returns 0 for new project' do
      completed = controller.calculate_completed_steps
      expect(completed).to eq(0)
    end
  end

  describe '#assess_construction_readiness' do
    it 'returns readiness data structure' do
      readiness = controller.assess_construction_readiness
      
      expect(readiness).to have_key(:critical_permits_ready)
      expect(readiness).to have_key(:technical_permits_ready)
      expect(readiness).to have_key(:overall_readiness)
      expect(readiness).to have_key(:missing_permits)
      expect(readiness).to have_key(:next_milestone)
    end

    it 'shows low readiness for new project' do
      readiness = controller.assess_construction_readiness
      
      expect(readiness[:critical_permits_ready]).to be false
      expect(readiness[:overall_readiness]).to eq(0)
    end
  end
end