require 'rails_helper'

RSpec.describe Immo::Promo::ProjectResourceService::ResourceAllocation do
  let(:test_class) do
    Class.new do
      include Immo::Promo::ProjectResourceService::ResourceAllocation
      include Immo::Promo::ProjectResourceService::WorkloadAnalysis
      include Immo::Promo::ProjectResourceService::UtilizationMetrics
      include Immo::Promo::ProjectResourceService::OptimizationRecommendations
      include Immo::Promo::ProjectResourceService::CapacityManagement
      
      attr_accessor :project, :capacity_service, :optimization_service, :skills_service
      
      def initialize(project)
        @project = project
        @capacity_service = double('capacity_service')
        @optimization_service = double('optimization_service')
        @skills_service = double('skills_service')
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { test_class.new(project) }

  describe '#resource_allocation_summary' do
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project) }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:task1) { create(:immo_promo_task, phase: phase, stakeholder: stakeholder1, estimated_hours: 100) }
    let!(:task2) { create(:immo_promo_task, phase: phase, stakeholder: stakeholder2, estimated_hours: 20) }

    before do
      allow(service.optimization_service).to receive(:optimize_assignments).and_return({})
      allow(service.capacity_service).to receive(:analyze_capacity).and_return({
        current_capacity: { utilization_rate: 75 },
        recommendations: ['Balance workload']
      })
      allow(service.skills_service).to receive(:analyze_skills_matrix).and_return({
        skill_gaps: []
      })
    end

    it 'returns comprehensive allocation summary' do
      summary = service.resource_allocation_summary
      
      expect(summary).to include(
        :stakeholders,
        :by_phase,
        :utilization_metrics,
        :conflicts,
        :recommendations,
        :current_allocation,
        :optimization_suggestions,
        :capacity_analysis
      )
    end

    it 'identifies overallocated stakeholders' do
      # Mock heavy workload for stakeholder1
      allow(service).to receive(:calculate_utilization_percentage).with(stakeholder1).and_return(120)
      allow(service).to receive(:calculate_utilization_percentage).with(stakeholder2).and_return(50)
      
      summary = service.resource_allocation_summary
      
      conflicts = summary[:conflicts]
      overallocation_conflict = conflicts.find { |c| c[:type] == 'overallocation' }
      
      expect(overallocation_conflict).not_to be_nil
      expect(overallocation_conflict[:severity]).to eq('high')
      expect(overallocation_conflict[:description]).to include('1 stakeholders are overallocated')
    end

    it 'builds phase allocation data' do
      summary = service.resource_allocation_summary
      
      phase_data = summary[:by_phase].first
      expect(phase_data).to include(
        phase: phase.name,
        status: phase.status,
        resource_count: 2,
        total_hours: 120,
        phase_id: phase.id,
        phase_type: phase.phase_type
      )
    end
  end

  describe '#stakeholder_allocation_summary' do
    let!(:available_stakeholder) { create(:immo_promo_stakeholder, project: project, is_active: true) }
    let!(:overloaded_stakeholder) { create(:immo_promo_stakeholder, project: project, is_active: true) }
    let!(:inactive_stakeholder) { create(:immo_promo_stakeholder, project: project, is_active: false) }

    before do
      allow(service).to receive(:calculate_utilization_percentage).with(available_stakeholder).and_return(25)
      allow(service).to receive(:calculate_utilization_percentage).with(overloaded_stakeholder).and_return(110)
    end

    it 'groups stakeholders by allocation status' do
      summary = service.stakeholder_allocation_summary
      
      expect(summary[:total]).to eq(2) # Only active stakeholders
      expect(summary[:by_status]['available']).to eq(1)
      expect(summary[:by_status]['overloaded']).to eq(1)
    end
  end

  describe '#resource_allocation_by_phase' do
    let!(:phase1) { create(:immo_promo_phase, project: project) }
    let!(:phase2) { create(:immo_promo_phase, project: project) }
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:task1) { create(:immo_promo_task, phase: phase1, stakeholder: stakeholder, estimated_hours: 40) }
    let!(:task2) { create(:immo_promo_task, phase: phase1, stakeholder: stakeholder, estimated_hours: 20) }

    it 'calculates resource allocation per phase' do
      allocations = service.resource_allocation_by_phase
      
      phase1_allocation = allocations.find { |a| a[:phase] == phase1.name }
      
      expect(phase1_allocation[:resource_count]).to eq(1)
      expect(phase1_allocation[:total_hours]).to eq(60)
      expect(phase1_allocation[:workload_distribution]).to be_a(Hash)
    end
  end
end