class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_reports_access!
  
  def index
    @reports = policy_scope(Report)
    @recent_reports = @reports.recent.limit(10)
    @report_categories = report_categories
  end
  
  def show
    @report = authorize Report.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf { send_data @report.generate_pdf, filename: "#{@report.name}.pdf", type: 'application/pdf' }
      format.xlsx { send_data @report.generate_excel, filename: "#{@report.name}.xlsx", type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
    end
  end
  
  def new
    @report = authorize Report.new
    @templates = ReportTemplate.active
  end
  
  def create
    @report = authorize Report.new(report_params)
    @report.created_by = current_user
    
    if @report.save
      ReportGenerationJob.perform_later(@report)
      redirect_to @report, notice: 'Rapport en cours de génération...'
    else
      @templates = ReportTemplate.active
      render :new, status: :unprocessable_entity
    end
  end
  
  def export
    @report = authorize Report.find(params[:id])
    format = params[:format_type] || 'pdf'
    
    case format
    when 'pdf'
      send_data @report.generate_pdf, filename: "#{@report.name}.pdf", type: 'application/pdf'
    when 'excel'
      send_data @report.generate_excel, filename: "#{@report.name}.xlsx", type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    when 'csv'
      send_data @report.generate_csv, filename: "#{@report.name}.csv", type: 'text/csv'
    end
  end
  
  private
  
  def authorize_reports_access!
    unless current_user.has_role?(:direction) || current_user.has_role?(:admin)
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  end
  
  def report_params
    params.require(:report).permit(:name, :report_type, :start_date, :end_date, 
                                   :template_id, :filters, :include_charts)
  end
  
  def report_categories
    {
      activity: 'Rapports d\'activité',
      financial: 'Rapports financiers',
      compliance: 'Rapports de conformité',
      performance: 'Rapports de performance',
      custom: 'Rapports personnalisés'
    }
  end
end