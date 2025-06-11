require 'rails_helper'

RSpec.describe Immo::Promo::ProjectResourceService::ConflictDetection do
  let(:test_class) do
    Class.new do
      include Immo::Promo::ProjectResourceService::ConflictDetection
      include Immo::Promo::ProjectResourceService::UtilizationMetrics
      include Immo::Promo::ProjectResourceService::CapacityManagement
      
      attr_accessor :project
      
      def initialize(project)
        @project = project
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { test_class.new(project) }

  describe '#resource_conflict_calendar' do
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project) }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }
    
    context 'with scheduling conflicts' do
      let!(:task1) do
        create(:immo_promo_task,
          stakeholder: stakeholder1,
          status: 'in_progress',
          start_date: Date.current,
          end_date: Date.current + 5.days
        )
      end
      
      let!(:task2) do
        create(:immo_promo_task,
          stakeholder: stakeholder1,
          status: 'pending',
          start_date: Date.current + 3.days,
          end_date: Date.current + 8.days
        )
      end

      it 'detects scheduling conflicts' do
        result = service.resource_conflict_calendar
        
        expect(result[:total_conflicts]).to eq(1)
        expect(result[:affected_resources]).to eq(1)
        expect(result[:conflicts_by_resource].first[:stakeholder]).to eq(stakeholder1)
      end

      it 'generates resolution suggestions' do
        result = service.resource_conflict_calendar
        
        suggestions = result[:resolution_suggestions]
        expect(suggestions).to be_an(Array)
        expect(suggestions.first[:options]).to include(
          match(/Reschedule/),
          match(/Assign.*to another resource/),
          match(/Negotiate extended timeline/),
          match(/Prioritize/)
        )
      end
    end
  end

  describe '#identify_resource_conflicts' do
    context 'overallocation conflicts' do
      let!(:overloaded) { create(:immo_promo_stakeholder, project: project) }
      let!(:normal) { create(:immo_promo_stakeholder, project: project) }
      
      before do
        create_list(:immo_promo_task, 10, 
          stakeholder: overloaded, 
          status: 'in_progress',
          estimated_hours: 20
        )
      end

      it 'identifies overallocated resources' do
        conflicts = service.identify_resource_conflicts
        
        overallocation = conflicts.find { |c| c[:type] == 'overallocation' }
        expect(overallocation).not_to be_nil
        expect(overallocation[:severity]).to eq('high')
        expect(overallocation[:resources]).to include(overloaded)
      end
    end

    context 'skill mismatch conflicts' do
      let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      let!(:task) do
        create(:immo_promo_task,
          stakeholder: stakeholder,
          required_skills: ['architecture', 'project_management']
        )
      end

      it 'identifies skill mismatches' do
        conflicts = service.identify_resource_conflicts
        
        skill_conflict = conflicts.find { |c| c[:type] == 'skill_mismatch' }
        expect(skill_conflict).not_to be_nil
        expect(skill_conflict[:severity]).to eq('medium')
      end
    end
  end

  describe 'private methods' do
    describe '#tasks_overlap?' do
      let(:task1) { double('task', start_date: Date.current, end_date: Date.current + 5.days) }
      let(:task2) { double('task', start_date: Date.current + 3.days, end_date: Date.current + 8.days) }
      let(:task3) { double('task', start_date: Date.current + 10.days, end_date: Date.current + 15.days) }

      it 'correctly identifies overlapping tasks' do
        expect(service.send(:tasks_overlap?, task1, task2)).to be true
        expect(service.send(:tasks_overlap?, task1, task3)).to be false
      end
    end

    describe '#calculate_overlap_days' do
      let(:task1) { double('task', start_date: Date.current, end_date: Date.current + 5.days) }
      let(:task2) { double('task', start_date: Date.current + 3.days, end_date: Date.current + 8.days) }

      it 'calculates correct overlap duration' do
        overlap = service.send(:calculate_overlap_days, task1, task2)
        expect(overlap).to eq(3) # Days 3, 4, and 5
      end
    end

    describe '#assess_overlap_severity' do
      it 'assigns severity based on task priorities' do
        critical_task = double('task', priority: 'critical')
        high_task = double('task', priority: 'high')
        normal_task = double('task', priority: 'normal')
        
        expect(service.send(:assess_overlap_severity, critical_task, normal_task)).to eq('high')
        expect(service.send(:assess_overlap_severity, high_task, normal_task)).to eq('medium')
        expect(service.send(:assess_overlap_severity, normal_task, normal_task)).to eq('low')
      end
    end
  end
end