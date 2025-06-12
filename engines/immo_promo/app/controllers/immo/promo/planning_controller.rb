module Immo
  module Promo
    class PlanningController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_planning_access!
  
  def index
    @projects = policy_scope(ImmoPromo::Project)
    @calendar_events = build_calendar_events
    @milestones = ImmoPromo::Milestone.upcoming.includes(:project)
    @resource_conflicts = detect_resource_conflicts
  end
  
  def show
    @project = authorize ImmoPromo::Project.find(params[:id])
    @phases = @project.phases.includes(:tasks)
    @gantt_data = build_gantt_data(@project)
    @critical_path = @project.critical_path_analysis
  end
  
  def calendar
    @view_type = params[:view] || 'month'
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @events = fetch_calendar_events(@date, @view_type)
    
    respond_to do |format|
      format.html
      format.json { render json: @events }
      format.ics { send_data generate_ical(@events), filename: 'planning.ics', type: 'text/calendar' }
    end
  end
  
  def timeline
    @projects = policy_scope(ImmoPromo::Project).active
    @timeline_data = build_timeline_data(@projects)
  end
  
  def update_task
    @task = authorize ImmoPromo::Task.find(params[:id])
    
    if @task.update(task_params)
      notify_task_update(@task)
      render json: { success: true, task: @task }
    else
      render json: { success: false, errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def reschedule
    @project = authorize ImmoPromo::Project.find(params[:id])
    new_start_date = Date.parse(params[:start_date])
    
    if @project.reschedule!(new_start_date)
      redirect_to planning_path(@project), notice: 'Planning mis à jour avec succès'
    else
      redirect_to planning_path(@project), alert: 'Erreur lors de la mise à jour du planning'
    end
  end
  
  private
  
  def authorize_planning_access!
    unless current_user.has_role?(:chef_projet) || current_user.has_role?(:direction) || current_user.has_role?(:admin)
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  end
  
  def task_params
    params.require(:task).permit(:name, :start_date, :end_date, :progress, :assigned_to_id)
  end
  
  def build_calendar_events
    events = []
    
    # Tasks
    ImmoPromo::Task.includes(:phase, :project).each do |task|
      events << {
        id: "task_#{task.id}",
        title: task.name,
        start: task.start_date,
        end: task.end_date,
        type: 'task',
        project: task.project.name,
        color: task_color(task)
      }
    end
    
    # Milestones
    ImmoPromo::Milestone.includes(:project).each do |milestone|
      events << {
        id: "milestone_#{milestone.id}",
        title: milestone.name,
        start: milestone.target_date,
        type: 'milestone',
        project: milestone.project.name,
        color: '#ff6b6b'
      }
    end
    
    events
  end
  
  def build_gantt_data(project)
    {
      tasks: project.phases.map do |phase|
        {
          id: "phase_#{phase.id}",
          name: phase.name,
          start: phase.start_date,
          end: phase.end_date,
          progress: phase.progress,
          children: phase.tasks.map do |task|
            {
              id: "task_#{task.id}",
              name: task.name,
              start: task.start_date,
              end: task.end_date,
              progress: task.progress,
              assigned_to: task.assigned_to&.name
            }
          end
        }
      end
    }
  end
  
  def detect_resource_conflicts
    # Détection des conflits de ressources
    conflicts = []
    # Implementation simplifiée
    conflicts
  end
  
  def task_color(task)
    case task.status
    when 'completed' then '#51cf66'
    when 'in_progress' then '#339af0'
    when 'delayed' then '#ff6b6b'
    else '#868e96'
    end
  end
  
  def notify_task_update(task)
    NotificationService.new.notify_task_update(task, current_user)
  end
  
  def generate_ical(events)
    # Génération format iCal
    "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//DocuSphere//Planning//FR\n" +
    events.map { |e| event_to_ical(e) }.join("\n") +
    "\nEND:VCALENDAR"
  end
  
  def event_to_ical(event)
    "BEGIN:VEVENT\nUID:#{event[:id]}@docusphere\nDTSTART:#{event[:start].strftime('%Y%m%d')}\nDTEND:#{event[:end]&.strftime('%Y%m%d') || event[:start].strftime('%Y%m%d')}\nSUMMARY:#{event[:title]}\nEND:VEVENT"
  end
  
  def fetch_calendar_events(date, view_type)
    range = case view_type
            when 'day' then date..date
            when 'week' then date.beginning_of_week..date.end_of_week
            when 'month' then date.beginning_of_month..date.end_of_month
            end
    
    build_calendar_events.select { |e| range.cover?(e[:start]) }
  end
  
  def build_timeline_data(projects)
    projects.map do |project|
      {
        id: project.id,
        name: project.name,
        start: project.start_date,
        end: project.target_completion_date,
        phases: project.phases.map { |p| { name: p.name, start: p.start_date, end: p.end_date } }
      }
    end
  end
    end
  end
end