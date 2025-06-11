require 'rails_helper'

RSpec.describe Immo::Promo::PermitWorkflow::WorkflowManagement, type: :concern do

  let(:controller_class) do
    Class.new(ApplicationController) do
      include Immo::Promo::PermitWorkflow::WorkflowManagement
      
      attr_accessor :project
      
      def initialize(project = nil)
        @project = project
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_type: 'residential') }
  let(:controller) { controller_class.new(project) }

  describe '#generate_workflow_for_project_type' do
    context 'for residential project' do
      it 'includes basic workflow plus residential steps' do
        workflow = controller.generate_workflow_for_project_type('residential')
        
        expect(workflow.length).to eq(4) # 3 base + 1 residential
        expect(workflow.last[:name]).to eq('Conformité accessibilité')
        expect(workflow.last[:permits_required]).to include('accessibility_compliance')
      end
    end

    context 'for commercial project' do
      it 'includes basic workflow plus commercial steps' do
        workflow = controller.generate_workflow_for_project_type('commercial')
        
        expect(workflow.length).to eq(5) # 3 base + 2 commercial
        expect(workflow[3][:name]).to eq('Autorisation commerciale')
        expect(workflow[4][:name]).to eq('Sécurité incendie')
      end
    end

    context 'for industrial project' do
      it 'includes basic workflow plus industrial steps' do
        workflow = controller.generate_workflow_for_project_type('industrial')
        
        expect(workflow.length).to eq(5) # 3 base + 2 industrial
        expect(workflow[3][:name]).to eq('Étude d\'impact environnemental')
        expect(workflow[4][:name]).to eq('Autorisations DREAL')
      end
    end

    context 'for unknown project type' do
      it 'returns only base workflow' do
        workflow = controller.generate_workflow_for_project_type('unknown')
        
        expect(workflow.length).to eq(3)
        expect(workflow.map { |step| step[:name] }).to eq([
          'Étude de faisabilité',
          'Dépôt permis d\'urbanisme',
          'Autorisations techniques'
        ])
      end
    end
  end

  describe '#determine_current_workflow_step' do
    let!(:urban_permit) { create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'approved') }
    let!(:construction_permit) { create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'pending') }

    it 'returns correct current step based on approved permits' do
      current_step = controller.determine_current_workflow_step
      
      # Should be on step 2 since urban_planning is approved but construction is not
      expect(current_step).to eq(2)
    end

    context 'when all permits are approved' do
      before do
        construction_permit.update(status: 'approved')
        create(:immo_promo_permit, project: project, permit_type: 'technical_authorizations', status: 'approved')
        create(:immo_promo_permit, project: project, permit_type: 'accessibility_compliance', status: 'approved')
      end

      it 'returns step beyond last workflow step' do
        current_step = controller.determine_current_workflow_step
        expect(current_step).to eq(5) # All 4 steps completed + 1
      end
    end
  end

  describe '#calculate_completed_steps' do
    let!(:urban_permit) { create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'approved') }

    it 'returns number of completed steps' do
      completed = controller.calculate_completed_steps
      expect(completed).to eq(1) # current step 2 - 1
    end
  end

  describe '#calculate_permit_dependencies' do
    let!(:urban_permit) { create(:immo_promo_permit, project: project, permit_type: 'urban_planning') }
    let!(:construction_permit) { create(:immo_promo_permit, project: project, permit_type: 'construction') }
    let!(:technical_permit) { create(:immo_promo_permit, project: project, permit_type: 'technical_authorizations') }

    it 'correctly identifies permit dependencies' do
      dependencies = controller.calculate_permit_dependencies
      
      # Construction depends on urban planning
      expect(dependencies[construction_permit.id]).to include(urban_permit)
      
      # Technical authorizations depend on construction
      expect(dependencies[technical_permit.id]).to include(construction_permit)
      
      # Urban planning has no dependencies
      expect(dependencies[urban_permit.id]).to be_empty
    end
  end

  describe '#identify_blocking_permits' do
    let!(:urban_permit) { create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'submitted') }
    let!(:construction_permit) { create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'draft') }

    it 'identifies permits that are blocking others' do
      blocking = controller.identify_blocking_permits
      
      expect(blocking.length).to eq(1)
      expect(blocking.first[:blocked_permit]).to eq(construction_permit)
      expect(blocking.first[:blocking_permit]).to eq(urban_permit)
      expect(blocking.first[:impact]).to eq('medium')
    end

    context 'when blocking permit is denied' do
      before { urban_permit.update(status: 'denied') }

      it 'marks impact as critical' do
        blocking = controller.identify_blocking_permits
        expect(blocking.first[:impact]).to eq('critical')
      end
    end
  end

  describe '#assess_construction_readiness' do
    let!(:urban_permit) { create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'approved') }
    let!(:construction_permit) { create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'approved') }

    it 'assesses construction readiness correctly' do
      readiness = controller.assess_construction_readiness
      
      expect(readiness[:critical_permits_ready]).to be true
      expect(readiness[:technical_permits_ready]).to be false
      expect(readiness[:overall_readiness]).to eq(50) # 2 out of 4 permits for residential
      expect(readiness[:missing_permits]).to include('technical_authorizations', 'accessibility_compliance')
    end

    context 'when all permits are ready' do
      before do
        create(:immo_promo_permit, project: project, permit_type: 'technical_authorizations', status: 'approved')
        create(:immo_promo_permit, project: project, permit_type: 'accessibility_compliance', status: 'approved')
      end

      it 'shows 100% readiness' do
        readiness = controller.assess_construction_readiness
        
        expect(readiness[:overall_readiness]).to eq(100)
        expect(readiness[:missing_permits]).to be_empty
        expect(readiness[:next_milestone]).to eq("Construction autorisée")
      end
    end
  end

  describe 'private methods' do
    describe '#get_required_permits_for_construction' do
      it 'returns correct permits for residential projects' do
        required = controller.send(:get_required_permits_for_construction)
        
        expect(required).to eq(%w[urban_planning construction technical_authorizations accessibility_compliance])
      end

      context 'for commercial project' do
        let(:project) { create(:immo_promo_project, organization: organization, project_type: 'commercial') }

        it 'includes commercial-specific permits' do
          required = controller.send(:get_required_permits_for_construction)
          
          expect(required).to include('commercial_authorization', 'fire_safety')
        end
      end

      context 'for industrial project' do
        let(:project) { create(:immo_promo_project, organization: organization, project_type: 'industrial') }

        it 'includes industrial-specific permits' do
          required = controller.send(:get_required_permits_for_construction)
          
          expect(required).to include('environmental_impact', 'icpe', 'dreal_authorization')
        end
      end
    end

    describe '#identify_missing_permits_for_construction' do
      let!(:urban_permit) { create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'approved') }

      it 'identifies missing permits' do
        missing = controller.send(:identify_missing_permits_for_construction)
        
        expect(missing).to include('construction', 'technical_authorizations', 'accessibility_compliance')
        expect(missing).not_to include('urban_planning')
      end
    end

    describe '#identify_next_construction_milestone' do
      context 'when critical permits are missing' do
        it 'returns the next critical permit' do
          milestone = controller.send(:identify_next_construction_milestone)
          expect(milestone).to eq('Urban planning')
        end
      end

      context 'when only non-critical permits are missing' do
        let!(:urban_permit) { create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'approved') }
        let!(:construction_permit) { create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'approved') }

        it 'returns the first missing permit' do
          milestone = controller.send(:identify_next_construction_milestone)
          expect(milestone).to eq('Technical authorizations')
        end
      end
    end
  end
end