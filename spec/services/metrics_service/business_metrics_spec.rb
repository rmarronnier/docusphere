require 'rails_helper'

RSpec.describe MetricsService::BusinessMetrics do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:service) { MetricsService.new(user) }
  
  # Access the module methods through the service instance
  subject { service }
  
  describe '#business_performance_metrics' do
    context 'with Immo::Promo data' do
      let!(:project) { create(:immo_promo_project, organization: organization) }
      let!(:permits) { create_list(:immo_promo_permit, 3, project: project, status: 'approved') }
      let!(:contracts) { create_list(:immo_promo_contract, 2, project: project, status: 'active') }
      
      it 'returns comprehensive business metrics' do
        result = subject.business_performance_metrics
        
        expect(result).to include(
          :permits,
          :contracts,
          :sales,
          :compliance,
          :overall_health
        )
      end
      
      it 'calculates permit metrics correctly' do
        create(:immo_promo_permit, project: project, status: 'pending')
        create(:immo_promo_permit, project: project, status: 'rejected')
        
        metrics = subject.business_performance_metrics
        
        expect(metrics[:permits]).to include(
          total: 5,
          approved: 3,
          pending: 1,
          rejected: 1,
          approval_rate: 60.0
        )
      end
      
      it 'calculates contract metrics' do
        create(:immo_promo_contract, project: project, status: 'terminated', amount_cents: 100_000_00)
        
        metrics = subject.business_performance_metrics
        
        expect(metrics[:contracts]).to include(
          total: 3,
          active: 2,
          terminated: 1
        )
        expect(metrics[:contracts][:total_value]).to be > 0
      end
    end
    
    context 'without Immo::Promo module' do
      it 'returns default metrics structure' do
        allow(subject).to receive(:defined?).with(Immo::Promo).and_return(false)
        
        result = subject.business_performance_metrics
        
        expect(result).to include(
          permits: { total: 0, approved: 0, pending: 0, rejected: 0, approval_rate: 0 },
          contracts: { total: 0, active: 0, terminated: 0, total_value: 0 },
          sales: { total: 0, completed: 0, in_progress: 0, conversion_rate: 0 }
        )
      end
    end
  end
  
  describe '#revenue_metrics' do
    context 'with financial data' do
      let!(:project) { create(:immo_promo_project, organization: organization) }
      let!(:budget) { create(:immo_promo_budget, project: project, planned_amount_cents: 1_000_000_00) }
      let!(:budget_lines) do
        [
          create(:immo_promo_budget_line, budget: budget, planned_amount_cents: 200_000_00, actual_amount_cents: 180_000_00),
          create(:immo_promo_budget_line, budget: budget, planned_amount_cents: 300_000_00, actual_amount_cents: 350_000_00)
        ]
      end
      
      it 'calculates revenue and budget metrics' do
        metrics = subject.revenue_metrics
        
        expect(metrics).to include(
          :total_budget,
          :spent_budget,
          :remaining_budget,
          :budget_utilization_rate,
          :cost_variance
        )
      end
      
      it 'calculates budget utilization correctly' do
        metrics = subject.revenue_metrics
        
        total_spent = 180_000_00 + 350_000_00
        utilization_rate = (total_spent.to_f / 1_000_000_00 * 100).round(2)
        
        expect(metrics[:spent_budget]).to eq(total_spent)
        expect(metrics[:budget_utilization_rate]).to eq(utilization_rate)
      end
    end
  end
  
  describe '#project_health_score' do
    let!(:project) { create(:immo_promo_project, organization: organization) }
    
    context 'with healthy project' do
      before do
        # On-time tasks
        create_list(:immo_promo_task, 8, project: project, status: 'completed', end_date: 1.day.from_now, actual_end_date: Time.current)
        create_list(:immo_promo_task, 2, project: project, status: 'in_progress')
        
        # Good budget
        budget = create(:immo_promo_budget, project: project, planned_amount_cents: 1_000_000_00)
        create(:immo_promo_budget_line, budget: budget, planned_amount_cents: 500_000_00, actual_amount_cents: 480_000_00)
      end
      
      it 'returns high health score' do
        score = subject.project_health_score(project.id)
        
        expect(score).to be > 80
      end
    end
    
    context 'with struggling project' do
      before do
        # Delayed tasks
        create_list(:immo_promo_task, 5, project: project, status: 'completed', end_date: 5.days.ago, actual_end_date: Time.current)
        create_list(:immo_promo_task, 5, project: project, status: 'overdue')
        
        # Over budget
        budget = create(:immo_promo_budget, project: project, planned_amount_cents: 1_000_000_00)
        create(:immo_promo_budget_line, budget: budget, planned_amount_cents: 500_000_00, actual_amount_cents: 750_000_00)
      end
      
      it 'returns low health score' do
        score = subject.project_health_score(project.id)
        
        expect(score).to be < 50
      end
    end
  end
  
  describe '#compliance_status' do
    it 'returns compliance metrics' do
      # Create documents with various validation states
      create_list(:document, 3, organization: organization, validation_status: 'approved')
      create_list(:document, 2, organization: organization, validation_status: 'pending')
      create(:document, organization: organization, validation_status: 'rejected')
      
      metrics = subject.compliance_status
      
      expect(metrics).to include(
        total_documents: 6,
        validated_documents: 3,
        pending_validations: 2,
        rejected_documents: 1,
        compliance_rate: 50.0
      )
    end
  end
  
  describe '#sales_performance' do
    context 'with Immo::Promo sales data' do
      let!(:project) { create(:immo_promo_project, organization: organization) }
      let!(:lots) { create_list(:immo_promo_lot, 10, project: project) }
      let!(:reservations) do
        [
          create(:immo_promo_reservation, lot: lots[0], status: 'confirmed'),
          create(:immo_promo_reservation, lot: lots[1], status: 'confirmed'),
          create(:immo_promo_reservation, lot: lots[2], status: 'pending'),
          create(:immo_promo_reservation, lot: lots[3], status: 'cancelled')
        ]
      end
      
      it 'calculates sales metrics' do
        metrics = subject.sales_performance
        
        expect(metrics).to include(
          total_lots: 10,
          sold_lots: 2,
          reserved_lots: 1,
          available_lots: 7,
          sales_rate: 20.0
        )
      end
    end
  end
end