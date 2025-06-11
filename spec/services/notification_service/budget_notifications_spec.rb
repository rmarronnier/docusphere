require 'rails_helper'

RSpec.describe NotificationService::BudgetNotifications do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:budget) { create(:immo_promo_budget, project: project) }
  let(:service) { NotificationService.new }
  
  describe '#notify_budget_exceeded' do
    let(:budget_line) { create(:immo_promo_budget_line, budget: budget, planned_amount_cents: 100_000_00, actual_amount_cents: 120_000_00) }
    
    it 'creates notifications for project stakeholders' do
      project_manager = project.project_manager
      finance_team = create_list(:user, 2, organization: organization)
      
      allow(service).to receive(:users_with_finance_role).and_return(finance_team)
      
      expect {
        service.notify_budget_exceeded(budget_line)
      }.to change(Notification, :count).by(3) # PM + 2 finance users
    end
    
    it 'includes budget details in notification' do
      service.notify_budget_exceeded(budget_line)
      
      notification = Notification.last
      expect(notification.title).to include('Budget Exceeded')
      expect(notification.message).to include(budget_line.name)
      expect(notification.message).to include('20%')
      expect(notification.notification_type).to eq('budget_alert')
      expect(notification.priority).to eq('high')
    end
    
    it 'sets correct metadata' do
      service.notify_budget_exceeded(budget_line)
      
      notification = Notification.last
      expect(notification.metadata).to include(
        'budget_line_id' => budget_line.id,
        'project_id' => project.id,
        'exceeded_by_percentage' => 20.0,
        'exceeded_by_amount' => 200_00
      )
    end
  end
  
  describe '#notify_budget_threshold_reached' do
    let(:budget) { create(:immo_promo_budget, project: project, planned_amount_cents: 1_000_000_00) }
    
    it 'creates warning notifications at different thresholds' do
      # 75% threshold
      service.notify_budget_threshold_reached(budget, 75)
      
      notification = Notification.last
      expect(notification.title).to include('75% of Budget')
      expect(notification.priority).to eq('medium')
      
      # 90% threshold
      service.notify_budget_threshold_reached(budget, 90)
      
      notification = Notification.last
      expect(notification.title).to include('90% of Budget')
      expect(notification.priority).to eq('high')
    end
    
    it 'includes remaining budget information' do
      service.notify_budget_threshold_reached(budget, 80)
      
      notification = Notification.last
      expect(notification.message).to include('20% remaining')
      expect(notification.metadata['remaining_percentage']).to eq(20)
    end
  end
  
  describe '#notify_budget_adjustment' do
    let(:adjustment_data) do
      {
        previous_amount: 100_000_00,
        new_amount: 150_000_00,
        reason: 'Scope expansion',
        adjusted_by: create(:user, organization: organization)
      }
    end
    
    it 'notifies relevant stakeholders of budget changes' do
      expect {
        service.notify_budget_adjustment(budget, adjustment_data)
      }.to change(Notification, :count)
    end
    
    it 'includes adjustment details' do
      service.notify_budget_adjustment(budget, adjustment_data)
      
      notification = Notification.last
      expect(notification.title).to include('Budget Adjusted')
      expect(notification.message).to include('50%')
      expect(notification.message).to include('Scope expansion')
    end
  end
  
  describe '#notify_budget_approval_required' do
    it 'creates approval request notifications' do
      approvers = create_list(:user, 2, organization: organization)
      allow(service).to receive(:budget_approvers).and_return(approvers)
      
      expect {
        service.notify_budget_approval_required(budget)
      }.to change(Notification, :count).by(2)
    end
    
    it 'marks notifications as requiring action' do
      service.notify_budget_approval_required(budget)
      
      notification = Notification.last
      expect(notification.requires_action).to be true
      expect(notification.action_url).to include("budgets/#{budget.id}")
    end
  end
  
  describe '#notify_budget_variance' do
    context 'with significant variance' do
      let(:variance_data) do
        {
          planned: 100_000_00,
          actual: 85_000_00,
          variance_percentage: -15,
          category: 'Construction'
        }
      end
      
      it 'creates variance alert' do
        service.notify_budget_variance(budget, variance_data)
        
        notification = Notification.last
        expect(notification.title).to include('Budget Variance Alert')
        expect(notification.message).to include('15% under budget')
        expect(notification.priority).to eq('medium')
      end
    end
    
    context 'with critical variance' do
      let(:variance_data) do
        {
          planned: 100_000_00,
          actual: 130_000_00,
          variance_percentage: 30,
          category: 'Materials'
        }
      end
      
      it 'creates high priority alert for large overruns' do
        service.notify_budget_variance(budget, variance_data)
        
        notification = Notification.last
        expect(notification.priority).to eq('high')
        expect(notification.message).to include('30% over budget')
      end
    end
  end
  
  describe '#notify_payment_milestone_reached' do
    let(:milestone_data) do
      {
        milestone_name: 'Foundation Complete',
        payment_amount: 250_000_00,
        due_date: 5.days.from_now
      }
    end
    
    it 'notifies finance team of payment milestones' do
      service.notify_payment_milestone_reached(project, milestone_data)
      
      notification = Notification.last
      expect(notification.title).to include('Payment Milestone')
      expect(notification.message).to include('Foundation Complete')
      expect(notification.message).to include('€2,500')
    end
    
    it 'sets reminder for due date' do
      service.notify_payment_milestone_reached(project, milestone_data)
      
      notification = Notification.last
      expect(notification.metadata['due_date']).to eq(milestone_data[:due_date].to_s)
      expect(notification.metadata['auto_reminder']).to be true
    end
  end
end