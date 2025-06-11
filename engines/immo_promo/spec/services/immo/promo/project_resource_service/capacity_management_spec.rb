require 'rails_helper'

RSpec.describe Immo::Promo::ProjectResourceService::CapacityManagement do
  let(:test_class) do
    Class.new do
      include Immo::Promo::ProjectResourceService::CapacityManagement
      include Immo::Promo::ProjectResourceService::ResourceAllocation # For resource_status
      
      attr_accessor :project, :capacity_service
      
      def initialize(project)
        @project = project
        @capacity_service = double('capacity_service')
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { test_class.new(project) }

  describe '#resource_capacity_planning' do
    it 'delegates to capacity service' do
      capacity_data = { current_capacity: 100, future_needs: 120 }
      expect(service.capacity_service).to receive(:analyze_capacity).and_return(capacity_data)
      
      result = service.resource_capacity_planning
      
      expect(result).to eq(capacity_data)
    end
  end

  describe '#calculate_availability' do
    let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:task1) { create(:immo_promo_task, stakeholder: stakeholder, status: 'in_progress', estimated_hours: 20) }
    let!(:task2) { create(:immo_promo_task, stakeholder: stakeholder, status: 'pending', estimated_hours: 10) }

    before do
      allow(service.capacity_service).to receive(:send).with(:calculate_weeks_remaining).and_return(2)
    end

    it 'calculates stakeholder availability' do
      availability = service.calculate_availability(stakeholder)
      
      expect(availability).to include(
        total_capacity: 40,
        allocated_hours: 15, # 30 hours / 2 weeks
        available_hours: 25,
        availability_percentage: 62.5,
        status: 'partially_allocated'
      )
    end

    context 'with no weeks remaining' do
      before do
        allow(service.capacity_service).to receive(:send).with(:calculate_weeks_remaining).and_return(0)
      end

      it 'handles edge case of zero weeks' do
        availability = service.calculate_availability(stakeholder)
        
        expect(availability[:allocated_hours]).to eq(40)
        expect(availability[:available_hours]).to eq(0)
      end
    end
  end

  describe '#can_handle_task?' do
    let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let(:task) { create(:immo_promo_task) }

    context 'with no required skills' do
      before do
        allow(task).to receive(:required_skills).and_return([])
      end

      it 'returns true' do
        expect(service.send(:can_handle_task?, stakeholder, task)).to be true
      end
    end

    context 'with required skills' do
      let!(:certification) { create(:immo_promo_certification, stakeholder: stakeholder, certification_type: 'project_management') }
      
      before do
        allow(task).to receive(:required_skills).and_return(['project_management', 'finance'])
      end

      it 'returns false if stakeholder lacks skills' do
        expect(service.send(:can_handle_task?, stakeholder, task)).to be false
      end

      it 'returns true if stakeholder has all skills' do
        create(:immo_promo_certification, stakeholder: stakeholder, certification_type: 'finance')
        
        expect(service.send(:can_handle_task?, stakeholder, task)).to be true
      end
    end

    context 'with user assignee' do
      let(:user) { create(:user) }
      
      it 'assumes users can handle basic tasks' do
        allow(task).to receive(:required_skills).and_return(['basic'])
        
        expect(service.send(:can_handle_task?, user, task)).to be true
      end
    end
  end
end