module Immo
  module Promo
    class ResourcesController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_resources_access!
  
  def index
    @resources = policy_scope(Resource)
    @teams = Team.includes(:members)
    @resource_allocation = calculate_resource_allocation
    @availability_matrix = build_availability_matrix
  end
  
  def show
    @resource = authorize Resource.find(params[:id])
    @current_assignments = @resource.current_assignments
    @availability = @resource.availability_calendar
    @skills = @resource.skills
    @performance_metrics = @resource.performance_metrics
  end
  
  def allocation
    @projects = ImmoPromo::Project.active.includes(:stakeholders)
    @allocation_data = StakeholderAllocationService.new.allocation_overview
    @conflicts = detect_allocation_conflicts
    
    respond_to do |format|
      format.html
      format.json { render json: @allocation_data }
      format.xlsx { send_data generate_allocation_report, filename: "allocation_#{Date.current}.xlsx" }
    end
  end
  
  def availability
    @date_range = parse_date_range
    @resources = Resource.includes(:assignments)
    @availability_data = calculate_availability(@resources, @date_range)
    
    respond_to do |format|
      format.html
      format.json { render json: @availability_data }
    end
  end
  
  def assign
    @resource = authorize Resource.find(params[:id])
    @project = ImmoPromo::Project.find(params[:project_id])
    @assignment = ResourceAssignment.new(assignment_params)
    
    if @assignment.valid? && assign_resource(@resource, @project, @assignment)
      redirect_to resources_path, notice: 'Ressource assignée avec succès'
    else
      redirect_to resources_path, alert: 'Erreur lors de l\'assignation'
    end
  end
  
  def workload
    @resource = authorize Resource.find(params[:id])
    @workload_data = calculate_workload(@resource)
    @recommendations = generate_workload_recommendations(@resource)
    
    respond_to do |format|
      format.html
      format.json { render json: { workload: @workload_data, recommendations: @recommendations } }
    end
  end
  
  def capacity_planning
    @teams = Team.all
    @capacity_data = TeamCapacityService.new.analyze_capacity
    @forecast = generate_capacity_forecast
  end
  
  def skills_matrix
    @resources = Resource.includes(:skills)
    @skills = Skill.all
    @matrix = build_skills_matrix(@resources, @skills)
    @gaps = identify_skill_gaps
  end
  
  private
  
  def authorize_resources_access!
    unless current_user.has_role?(:chef_projet) || current_user.has_role?(:direction) || current_user.has_role?(:admin)
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  end
  
  def assignment_params
    params.require(:assignment).permit(:start_date, :end_date, :allocation_percentage, :role)
  end
  
  def calculate_resource_allocation
    allocations = {}
    Resource.includes(:assignments).each do |resource|
      allocations[resource.id] = {
        name: resource.name,
        current_load: resource.current_workload_percentage,
        available_capacity: resource.available_capacity,
        assignments: resource.assignments.active.count
      }
    end
    allocations
  end
  
  def build_availability_matrix
    matrix = {}
    dates = (Date.current..Date.current + 30.days).to_a
    
    Resource.all.each do |resource|
      matrix[resource.id] = dates.map do |date|
        { date: date, available: resource.available_on?(date) }
      end
    end
    
    matrix
  end
  
  def detect_allocation_conflicts
    conflicts = []
    Resource.includes(:assignments).each do |resource|
      if resource.overallocated?
        conflicts << {
          resource: resource,
          message: "Surallocation: #{resource.current_workload_percentage}%",
          severity: 'high'
        }
      end
    end
    conflicts
  end
  
  def calculate_availability(resources, date_range)
    resources.map do |resource|
      {
        id: resource.id,
        name: resource.name,
        availability: resource.availability_in_range(date_range),
        assignments: resource.assignments_in_range(date_range)
      }
    end
  end
  
  def assign_resource(resource, project, assignment)
    ActiveRecord::Base.transaction do
      stakeholder = ImmoPromo::Stakeholder.create!(
        project: project,
        name: resource.name,
        email: resource.email,
        role: assignment.role,
        assigned_from: assignment.start_date,
        assigned_to: assignment.end_date
      )
      
      resource.assignments.create!(
        assignable: stakeholder,
        start_date: assignment.start_date,
        end_date: assignment.end_date,
        allocation_percentage: assignment.allocation_percentage
      )
    end
  end
  
  def calculate_workload(resource)
    {
      current_week: resource.workload_for_week(Date.current),
      current_month: resource.workload_for_month(Date.current),
      forecast: resource.workload_forecast(3.months)
    }
  end
  
  def generate_workload_recommendations(resource)
    recommendations = []
    
    if resource.overallocated?
      recommendations << {
        type: 'warning',
        message: 'Ressource surallouée',
        action: 'Réduire les assignations ou augmenter la capacité'
      }
    end
    
    if resource.underutilized?
      recommendations << {
        type: 'info',
        message: 'Capacité disponible',
        action: 'Considérer de nouvelles assignations'
      }
    end
    
    recommendations
  end
  
  def generate_capacity_forecast
    # Prévisions de capacité basées sur les projets planifiés
    {}
  end
  
  def build_skills_matrix(resources, skills)
    matrix = {}
    resources.each do |resource|
      matrix[resource.id] = skills.map do |skill|
        resource.has_skill?(skill) ? resource.skill_level(skill) : 0
      end
    end
    matrix
  end
  
  def identify_skill_gaps
    # Identification des compétences manquantes par rapport aux besoins projets
    []
  end
  
  def parse_date_range
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : start_date + 30.days
    start_date..end_date
  end
  
  def generate_allocation_report
    # Génération du rapport Excel d'allocation
    ""
  end
    end
  end
end