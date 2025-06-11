module Immo
  module Promo
    class FinancialDashboardController < Immo::Promo::ApplicationController
      include FinancialDashboard::BudgetAnalysis
      include FinancialDashboard::CashFlowManagement
      include FinancialDashboard::ProfitabilityTracking
      include FinancialDashboard::BudgetAdjustments
      include FinancialDashboard::ReportGeneration
      
      before_action :set_project
      before_action :authorize_financial_access

      def dashboard
        @budget_service = Immo::Promo::ProjectBudgetService.new(@project)
        @budget_summary = @budget_service.budget_summary
        @cost_tracking = @budget_service.cost_tracking_report
        @forecast = @budget_service.budget_forecast
        @cash_flow = @budget_service.cash_flow_analysis
        @optimization_suggestions = @budget_service.budget_optimization_suggestions
        
        respond_to do |format|
          format.html
          format.json { render json: financial_dashboard_data }
        end
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def authorize_financial_access
        authorize @project, :manage_finances?
      end

      def financial_dashboard_data
        {
          project: {
            id: @project.id,
            name: @project.name,
            reference: @project.reference_number
          },
          budget_summary: @budget_summary,
          cost_tracking: @cost_tracking,
          forecast: @forecast,
          cash_flow: @cash_flow,
          optimization_suggestions: @optimization_suggestions
        }
      end
    end
  end
end