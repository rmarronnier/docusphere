module Immo
  module Promo
    class RiskMonitoringController < Immo::Promo::ApplicationController
      include RiskMonitoring::RiskManagement
      include RiskMonitoring::RiskAssessment
      include RiskMonitoring::MitigationManagement
      include RiskMonitoring::AlertManagement
      include RiskMonitoring::ReportGeneration
      
      before_action :set_project
      before_action :authorize_risk_management

      def dashboard
        @risk_service = ProjectRiskService.new(@project)
        @risk_overview = @risk_service.risk_overview
        @active_risks = @risk_service.active_risks
        @risk_matrix = @risk_service.generate_risk_matrix
        @mitigation_status = @risk_service.mitigation_tracking
        @alerts = generate_risk_alerts
        
        respond_to do |format|
          format.html
          format.json { render json: risk_dashboard_data }
        end
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def authorize_risk_management
        authorize @project, :manage_risks?
      end

      def risk_dashboard_data
        {
          project: {
            id: @project.id,
            name: @project.name,
            reference: @project.reference_number
          },
          risk_overview: @risk_overview,
          active_risks: @active_risks,
          risk_matrix: @risk_matrix,
          mitigation_status: @mitigation_status,
          alerts: @alerts
        }
      end
    end
  end
end