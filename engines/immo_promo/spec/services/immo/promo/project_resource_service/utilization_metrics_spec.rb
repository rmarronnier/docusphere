require 'rails_helper'

RSpec.describe Immo::Promo::ProjectResourceService::UtilizationMetrics do
  let(:test_class) do
    Class.new do
      include Immo::Promo::ProjectResourceService::UtilizationMetrics
      
      attr_accessor :project
      
      def initialize(project)
        @project = project
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { test_class.new(project) }

  describe '#resource_utilization_overview' do
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project) }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }
    let!(:stakeholder3) { create(:immo_promo_stakeholder, project: project) }
    
    before do
      # Mock utilization percentages
      allow(service).to receive(:calculate_utilization_percentage).with(stakeholder1).and_return(25)
      allow(service).to receive(:calculate_utilization_percentage).with(stakeholder2).and_return(75)
      allow(service).to receive(:calculate_utilization_percentage).with(stakeholder3).and_return(110)
    end

    it 'returns comprehensive utilization overview' do
      overview = service.resource_utilization_overview
      
      expect(overview).to include(
        total_resources: 3,
        average_utilization: 70.0,
        underutilized: 1,
        optimal: 1,
        overutilized: 1
      )
      
      expect(overview[:distribution]).to eq({
        'underutilized' => 1,
        'optimal' => 1,
        'overutilized' => 1
      })
      
      expect(overview[:by_resource]).to be_an(Array)
      expect(overview[:by_resource].length).to eq(3)
    end

    it 'includes detailed resource information' do
      overview = service.resource_utilization_overview
      
      resource_info = overview[:by_resource].first
      expect(resource_info).to include(
        :resource,
        :utilization_percentage,
        :status,
        :allocated_hours,
        :available_hours,
        :task_count
      )
    end
  end

  describe '#calculate_utilization_percentage' do
    let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    
    context 'with tasks' do
      let!(:task1) { create(:immo_promo_task, stakeholder: stakeholder, estimated_hours: 20, status: 'in_progress') }
      let!(:task2) { create(:immo_promo_task, stakeholder: stakeholder, estimated_hours: 30, status: 'pending') }
      let!(:completed_task) { create(:immo_promo_task, stakeholder: stakeholder, estimated_hours: 10, status: 'completed') }

      it 'calculates utilization based on active tasks' do
        utilization = service.calculate_utilization_percentage(stakeholder)
        
        # 50 hours of active tasks / 40 hours per week = 125%
        expect(utilization).to eq(125)
      end
    end

    context 'without tasks' do
      it 'returns 0 utilization' do
        utilization = service.calculate_utilization_percentage(stakeholder)
        expect(utilization).to eq(0)
      end
    end

    context 'with user assignee' do
      let(:user) { create(:user) }
      let!(:task) { create(:immo_promo_task, assignee: user, estimated_hours: 20, status: 'in_progress') }

      it 'calculates utilization for users' do
        utilization = service.calculate_utilization_percentage(user)
        expect(utilization).to eq(50) # 20 hours / 40 hours = 50%
      end
    end
  end

  describe '#resource_availability_matrix' do
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project) }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }
    let(:date_range) { Date.current..Date.current + 30.days }

    before do
      # Create tasks with different schedules
      create(:immo_promo_task, 
        stakeholder: stakeholder1,
        start_date: Date.current,
        end_date: Date.current + 10.days,
        estimated_hours: 40
      )
      
      create(:immo_promo_task,
        stakeholder: stakeholder2,
        start_date: Date.current + 5.days,
        end_date: Date.current + 15.days,
        estimated_hours: 80
      )
    end

    it 'generates availability matrix' do
      matrix = service.resource_availability_matrix(date_range)
      
      expect(matrix).to be_an(Array)
      expect(matrix.length).to eq(2)
      
      resource_data = matrix.first
      expect(resource_data).to include(
        :resource,
        :total_capacity,
        :allocated_hours,
        :available_hours,
        :availability_by_week
      )
    end

    it 'calculates weekly availability' do
      matrix = service.resource_availability_matrix(date_range)
      
      availability_by_week = matrix.first[:availability_by_week]
      expect(availability_by_week).to be_a(Hash)
      
      # Should have entries for each week in the range
      expect(availability_by_week.keys.length).to be > 0
      
      week_data = availability_by_week.values.first
      expect(week_data).to include(
        :capacity,
        :allocated,
        :available,
        :utilization_percentage
      )
    end
  end

  describe 'private methods' do
    describe '#categorize_utilization' do
      it 'categorizes utilization levels correctly' do
        expect(service.send(:categorize_utilization, 25)).to eq('underutilized')
        expect(service.send(:categorize_utilization, 75)).to eq('optimal')
        expect(service.send(:categorize_utilization, 110)).to eq('overutilized')
      end
    end

    describe '#calculate_weekly_allocation' do
      let(:stakeholder) { create(:immo_promo_stakeholder) }
      let(:week_start) { Date.current.beginning_of_week }
      let(:week_end) { week_start + 6.days }
      
      let!(:task) do
        create(:immo_promo_task,
          stakeholder: stakeholder,
          start_date: week_start - 2.days,
          end_date: week_end + 2.days,
          estimated_hours: 50
        )
      end

      it 'calculates allocation for a specific week' do
        allocation = service.send(:calculate_weekly_allocation, stakeholder, week_start, week_end)
        
        # Task spans 11 days (including before and after week)
        # Week contains 7 days, so allocation = 50 * (7/11) ≈ 31.8
        expect(allocation).to be_within(1).of(32)
      end
    end
  end
end