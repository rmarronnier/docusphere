class Immo::Promo::ProjectsController < Immo::Promo::ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy]
  
  def index
    @projects = policy_scope(Immo::Promo::Project).includes(:project_manager, :organization)
    @projects = @projects.where(project_type: params[:type]) if params[:type].present?
    @projects = @projects.where(status: params[:status]) if params[:status].present?
    @projects = @projects.page(params[:page])
  end

  def show
    authorize @project
    @phases = @project.phases.order(:position)
    @recent_milestones = @project.milestones.recent.limit(5)
    @active_risks = @project.risks.active.high_priority.limit(3)
  end

  def new
    @project = current_user.organization.immo_promo_projects.build
    authorize @project
  end

  def create
    @project = current_user.organization.immo_promo_projects.build(project_params)
    @project.project_manager = current_user
    authorize @project

    respond_to do |format|
      if @project.save
        create_default_phases
        format.html { redirect_to immo_promo_project_path(@project), notice: 'Projet créé avec succès.' }
        format.json { render json: { success: true, redirect_url: immo_promo_project_path(@project) } }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @project.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize @project
  end

  def update
    authorize @project
    
    if @project.update(project_params)
      redirect_to immo_promo_project_path(@project), notice: 'Projet mis à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project
    
    if @project.destroy
      redirect_to immo_promo_projects_path, notice: 'Projet supprimé avec succès.'
    else
      redirect_to immo_promo_project_path(@project), alert: 'Impossible de supprimer le projet.'
    end
  end

  def dashboard
    # Dashboard global ou par projet selon la présence d'un ID
    if params[:id].present?
      # Dashboard spécifique à un projet
      @project = policy_scope(Immo::Promo::Project).find(params[:id])
      authorize @project
      @projects = [@project]  # Make sure @projects is always defined
      project_ids = [@project.id]
    else
      # Dashboard global - autoriser avec la classe Project
      authorize Immo::Promo::Project
      @projects = policy_scope(Immo::Promo::Project).active
      project_ids = @projects.pluck(:id)
    end
    
    @upcoming_milestones = Immo::Promo::Milestone.joins(:project)
                                                 .where(project_id: project_ids)
                                                 .upcoming
                                                 .limit(10)
    @overdue_tasks = Immo::Promo::Task.joins(phase: :project)
                                      .where(immo_promo_phases: { project_id: project_ids })
                                      .overdue
                                      .limit(10)
    @recent_reports = Immo::Promo::ProgressReport.joins(:project)
                                                 .where(project_id: project_ids)
                                                 .recent
                                                 .limit(5)
  end

  private

  def set_project
    @project = policy_scope(Immo::Promo::Project).find(params[:id])
  end

  def project_params
    params.require(:immo_promo_project).permit(
      :name, :reference, :description, :project_type, :status,
      :address, :city, :postal_code, :country,
      :start_date, :end_date, :total_budget_cents, :total_units,
      :total_surface_area, :notes, :project_manager_id
    )
  end

  def create_default_phases
    start_date = Date.today
    
    default_phases = [
      { name: 'Études préliminaires', phase_type: 'studies', position: 1, duration_months: 3 },
      { name: 'Obtention des permis', phase_type: 'permits', position: 2, duration_months: 6 },
      { name: 'Travaux de construction', phase_type: 'construction', position: 3, duration_months: 18 },
      { name: 'Réception des travaux', phase_type: 'reception', position: 4, duration_months: 1 },
      { name: 'Livraison', phase_type: 'delivery', position: 5, duration_months: 2 }
    ]

    default_phases.each do |phase_attrs|
      duration = phase_attrs.delete(:duration_months)
      end_date = start_date + duration.months
      
      @project.phases.create!(
        phase_attrs.merge(
          start_date: start_date,
          end_date: end_date
        )
      )
      
      start_date = end_date + 1.day
    end
  end
end