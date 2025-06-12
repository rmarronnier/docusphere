class LegalContractsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_juridique_access!
  before_action :set_contract, only: [:show, :edit, :update, :destroy, :validate, :review, :archive]
  
  def index
    @contracts = policy_scope(Contract)
    @filter = params[:filter] || 'active'
    
    @contracts = case @filter
                 when 'pending_review' then @contracts.pending_legal_review
                 when 'under_negotiation' then @contracts.under_negotiation
                 when 'approved' then @contracts.legally_approved
                 when 'archived' then @contracts.archived
                 else @contracts.requiring_legal_attention
                 end
    
    @contracts = @contracts.includes(:client, :legal_reviews, :clauses).order(updated_at: :desc)
    @compliance_summary = calculate_compliance_summary
    @risk_assessment = assess_contract_risks
  end
  
  def show
    @legal_reviews = @contract.legal_reviews.includes(:reviewer)
    @clauses = @contract.clauses.includes(:clause_template)
    @compliance_checks = @contract.compliance_checks
    @risk_analysis = analyze_contract_risks(@contract)
    @related_contracts = @contract.related_contracts
  end
  
  def new
    @contract = authorize Contract.new
    @contract.contract_type = 'legal'
    @legal_templates = LegalTemplate.active.by_category
    @standard_clauses = StandardClause.active
  end
  
  def create
    @contract = authorize Contract.new(legal_contract_params)
    @contract.created_by = current_user
    @contract.legal_owner = current_user
    @contract.status = 'draft'
    
    if @contract.save
      attach_standard_clauses if params[:standard_clause_ids]
      LegalReviewJob.perform_later(@contract)
      redirect_to @contract, notice: 'Contrat juridique créé avec succès'
    else
      @legal_templates = LegalTemplate.active.by_category
      @standard_clauses = StandardClause.active
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @legal_templates = LegalTemplate.active.by_category
    @standard_clauses = StandardClause.active
  end
  
  def update
    if @contract.update(legal_contract_params)
      @contract.create_legal_version!(current_user)
      ComplianceCheckJob.perform_later(@contract)
      redirect_to @contract, notice: 'Contrat juridique mis à jour avec succès'
    else
      @legal_templates = LegalTemplate.active.by_category
      @standard_clauses = StandardClause.active
      render :edit, status: :unprocessable_entity
    end
  end
  
  def validate
    @legal_review = @contract.legal_reviews.build(
      reviewer: current_user,
      status: params[:status],
      comments: params[:comments],
      risk_level: params[:risk_level]
    )
    
    if @legal_review.save
      @contract.update_legal_status!
      NotificationService.new.notify_legal_validation(@contract, @legal_review)
      redirect_to @contract, notice: 'Validation juridique enregistrée'
    else
      redirect_to @contract, alert: 'Erreur lors de la validation'
    end
  end
  
  def review
    @review_checklist = LegalReviewChecklist.for_contract_type(@contract.contract_type)
    @previous_reviews = @contract.legal_reviews.completed
    @compliance_issues = @contract.compliance_issues
  end
  
  def archive
    if @contract.can_be_archived?
      @contract.archive!(reason: params[:reason], archived_by: current_user)
      redirect_to legal_contracts_path, notice: 'Contrat archivé avec succès'
    else
      redirect_to @contract, alert: 'Ce contrat ne peut pas être archivé'
    end
  end
  
  def compliance_dashboard
    @compliance_metrics = calculate_compliance_metrics
    @upcoming_deadlines = Contract.upcoming_legal_deadlines
    @non_compliant_contracts = Contract.non_compliant
    @regulatory_updates = RegulatoryUpdate.recent
  end
  
  def clause_library
    @clauses = StandardClause.includes(:category)
    @categories = ClauseCategory.all
    @recent_updates = StandardClause.recently_updated
  end
  
  def generate_legal_report
    @start_date = params[:start_date] || 1.month.ago
    @end_date = params[:end_date] || Date.current
    @report_type = params[:report_type] || 'compliance'
    
    @report = LegalReportService.new(
      start_date: @start_date,
      end_date: @end_date,
      report_type: @report_type,
      user: current_user
    ).generate
    
    respond_to do |format|
      format.pdf { send_data @report.to_pdf, filename: "legal_report_#{@report_type}_#{Date.current}.pdf" }
      format.xlsx { send_data @report.to_excel, filename: "legal_report_#{@report_type}_#{Date.current}.xlsx" }
    end
  end
  
  private
  
  def authorize_juridique_access!
    unless current_user.has_role?(:juridique) || current_user.has_role?(:direction) || current_user.has_role?(:admin)
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  end
  
  def set_contract
    @contract = authorize Contract.find(params[:id])
  end
  
  def legal_contract_params
    params.require(:contract).permit(:title, :client_id, :contract_type, :legal_category,
                                    :governing_law, :jurisdiction, :dispute_resolution,
                                    :confidentiality_level, :liability_cap, :indemnification,
                                    :force_majeure, :termination_clauses, :start_date,
                                    :end_date, :amount, :special_conditions,
                                    standard_clause_ids: [])
  end
  
  def calculate_compliance_summary
    {
      total_contracts: @contracts.count,
      compliant: @contracts.compliant.count,
      non_compliant: @contracts.non_compliant.count,
      pending_review: @contracts.pending_legal_review.count,
      high_risk: @contracts.high_legal_risk.count
    }
  end
  
  def assess_contract_risks
    RiskAssessmentService.new(@contracts).assess_portfolio_risks
  end
  
  def analyze_contract_risks(contract)
    {
      risk_score: contract.calculate_risk_score,
      risk_factors: contract.identify_risk_factors,
      mitigation_suggestions: contract.suggest_risk_mitigations,
      compliance_status: contract.check_compliance
    }
  end
  
  def attach_standard_clauses
    clause_ids = params[:standard_clause_ids].reject(&:blank?)
    clause_ids.each do |clause_id|
      @contract.contract_clauses.create(standard_clause_id: clause_id)
    end
  end
  
  def calculate_compliance_metrics
    {
      overall_compliance_rate: Contract.compliance_rate,
      gdpr_compliance: Contract.gdpr_compliant.count,
      regulatory_violations: Contract.with_violations.count,
      upcoming_audits: Contract.upcoming_audits.count
    }
  end
end