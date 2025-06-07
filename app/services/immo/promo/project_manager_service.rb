class Immo::Promo::ProjectManagerService
  attr_reader :project, :current_user

  def initialize(project, current_user)
    @project = project
    @current_user = current_user
  end

  def calculate_overall_progress
    return 0 if project.phases.empty?
    
    total_weight = project.phases.sum { |phase| phase_weight(phase) }
    return 0 if total_weight == 0
    
    weighted_progress = project.phases.sum do |phase|
      phase.completion_percentage * phase_weight(phase)
    end
    
    (weighted_progress / total_weight).round(2)
  end

  def identify_critical_path
    # Simplified critical path calculation
    # In a real implementation, you'd use a proper CPM algorithm
    
    # Include phases that are either critical, have dependencies, or are permits/construction type
    critical_phases = project.phases
                            .left_joins(:phase_dependencies)
                            .where(
                              'immo_promo_phases.is_critical = ? OR immo_promo_phases.phase_type IN (?) OR immo_promo_phase_dependencies.id IS NOT NULL',
                              true,
                              ['permits', 'construction']
                            )
                            .distinct
                            .order(:position)
    
    # If no critical phases found, include all phases as potentially critical
    critical_phases = project.phases.order(:position) if critical_phases.empty?
    
    critical_phases.map do |phase|
      {
        phase: phase,
        slack_time: calculate_slack_time(phase),
        is_on_critical_path: calculate_slack_time(phase) <= 0
      }
    end
  end
  
  def calculate_critical_path
    identify_critical_path
  end

  def generate_schedule_alerts
    alerts = []
    
    # Overdue milestones
    overdue_milestones = Immo::Promo::Milestone.joins(:phase)
                                               .where(phase: { project_id: project.id })
                                               .where('target_date < ? AND immo_promo_milestones.status != ?', Date.current, 'completed')
    overdue_milestones.each do |milestone|
      alerts << {
        type: 'danger',
        title: 'Jalon en retard',
        message: "#{milestone.name} était prévu pour le #{milestone.target_date.strftime('%d/%m/%Y')}",
        resource: milestone
      }
    end
    
    # Upcoming critical milestones
    upcoming_critical = Immo::Promo::Milestone.joins(:phase)
                                              .where(phase: { project_id: project.id })
                                              .where(
      is_critical: true,
      target_date: Date.current..1.week.from_now,
      'immo_promo_milestones.status': 'pending'
    )
    upcoming_critical.each do |milestone|
      alerts << {
        type: 'warning',
        title: 'Jalon critique imminent',
        message: "#{milestone.name} prévu pour le #{milestone.target_date.strftime('%d/%m/%Y')}",
        resource: milestone
      }
    end
    
    # Permits expiring soon
    expiring_permits = project.permits.expiring_soon
    expiring_permits.each do |permit|
      alerts << {
        type: 'warning',
        title: 'Permis expirant bientôt',
        message: "#{permit.permit_type.humanize} expire le #{permit.expiry_date.strftime('%d/%m/%Y')}",
        resource: permit
      }
    end
    
    alerts
  end

  def validate_project_constraints
    errors = []
    
    # Check if construction can start
    if project.status == 'construction' && !project.can_start_construction?
      errors << "Impossible de démarrer la construction sans permis de construire approuvé"
    end
    
    # Check phase dependencies
    project.phases.each do |phase|
      unless phase.can_start?
        prerequisite_names = phase.prerequisite_phases.where.not(status: 'completed').pluck(:name)
        if prerequisite_names.any?
          errors << "La phase '#{phase.name}' ne peut pas démarrer : phases prérequises non terminées (#{prerequisite_names.join(', ')})"
        end
      end
    end
    
    # Check budget constraints
    if project.current_budget && project.total_budget
      if project.current_budget > project.total_budget
        errors << "Budget dépassé : #{project.current_budget.format} / #{project.total_budget.format}"
      end
    end
    
    errors
  end

  def generate_progress_report
    {
      project: project,
      date: Date.current,
      overall_progress: calculate_overall_progress,
      phases_progress: project.phases.map do |phase|
        {
          name: phase.name,
          type: phase.phase_type,
          status: phase.status,
          progress: phase.completion_percentage,
          start_date: phase.start_date,
          end_date: phase.end_date,
          is_delayed: phase.is_delayed?,
          task_count: phase.tasks.count,
          completed_tasks: phase.tasks.where(status: 'completed').count
        }
      end,
      key_metrics: {
        total_phases: project.phases.count,
        completed_phases: project.phases.where(status: 'completed').count,
        total_tasks: project.phases.joins(:tasks).count,
        completed_tasks: project.phases.joins(:tasks).where(tasks: { status: 'completed' }).count,
        critical_milestones: Immo::Promo::Milestone.joins(:phase).where(phase: { project_id: project.id }, is_critical: true).count,
        overdue_items: calculate_delays.values.flatten.count
      },
      critical_path: identify_critical_path,
      alerts: generate_schedule_alerts,
      constraints: validate_project_constraints,
      budget_status: {
        allocated: project.total_budget,
        used: project.current_budget,
        percentage_used: project.total_budget && project.current_budget && project.total_budget.amount > 0 ? 
          ((project.current_budget.amount.to_f / project.total_budget.amount.to_f) * 100).round(2) : 0
      }
    }
  end

  def optimize_resource_allocation
    optimization_suggestions = []
    
    # Find phases with overallocated resources
    project.phases.includes(:tasks).each do |phase|
      overloaded_users = find_overloaded_users_in_phase(phase)
      if overloaded_users.any?
        optimization_suggestions << {
          type: 'resource_optimization',
          phase: phase,
          issue: 'Utilisateurs surchargés',
          users: overloaded_users,
          suggestion: 'Redistribuer les tâches ou ajouter des ressources'
        }
      end
    end
    
    # Find idle resources
    idle_stakeholders = project.stakeholders.active.joins(:tasks)
                                                   .where(immo_promo_tasks: { status: ['pending', 'in_progress'] })
                                                   .group('immo_promo_stakeholders.id')
                                                   .having('COUNT(immo_promo_tasks.id) < 2')
    
    if idle_stakeholders.any?
      optimization_suggestions << {
        type: 'resource_utilization',
        issue: 'Intervenants sous-utilisés',
        stakeholders: idle_stakeholders,
        suggestion: 'Assigner plus de tâches ou réduire les équipes'
      }
    end
    
    {
      recommendations: optimization_suggestions,
      summary: {
        overloaded_resources: optimization_suggestions.count { |s| s[:type] == 'resource_optimization' },
        underutilized_resources: optimization_suggestions.count { |s| s[:type] == 'resource_utilization' }
      }
    }
  end

  private

  def phase_weight(phase)
    # Weight phases based on importance and type
    case phase.phase_type
    when 'construction' then 50
    when 'permits' then 30
    when 'studies' then 15
    when 'reception' then 3
    when 'delivery' then 2
    else 10
    end
  end

  def calculate_slack_time(phase)
    return Float::INFINITY unless phase.end_date
    
    # Calculate the difference between latest allowable finish and scheduled finish
    latest_finish = calculate_latest_finish_time(phase)
    scheduled_finish = phase.end_date
    
    (latest_finish - scheduled_finish).to_f / 1.day
  end

  def calculate_latest_finish_time(phase)
    # Find the minimum start time of all dependent phases
    dependent_phases = Immo::Promo::PhaseDependency.where(prerequisite_phase: phase)
                                                  .includes(:dependent_phase)
                                                  .map(&:dependent_phase)
    
    if dependent_phases.empty?
      # If no dependent phases, use project end date
      project.end_date || 1.year.from_now
    else
      dependent_phases.map(&:start_date).compact.min || project.end_date || 1.year.from_now
    end
  end

  def find_overloaded_users_in_phase(phase)
    # Find users with more than 40 hours/week allocated in active tasks
    overloaded_user_ids = phase.tasks.where(status: ['pending', 'in_progress'])
                                     .where.not(assigned_to_id: nil)
                                     .group(:assigned_to_id)
                                     .having('SUM(estimated_hours) > 40')
                                     .pluck(:assigned_to_id)
    
    User.where(id: overloaded_user_ids)
  end
  
  def stakeholder_workload(stakeholder)
    # Calculate total workload hours for a stakeholder
    stakeholder.tasks
               .where(status: ['pending', 'in_progress'])
               .sum(:estimated_hours)
  end
  
  def task_criticality_score(task)
    score = 0
    
    # Priority scoring
    case task.priority
    when 'critical' then score += 100
    when 'high' then score += 75
    when 'medium' then score += 50
    when 'low' then score += 25
    end
    
    # Deadline scoring
    if task.end_date
      days_until_due = (task.end_date.to_date - Date.current).to_i
      if days_until_due < 0
        score += 150 # Overdue
      elsif days_until_due <= 3
        score += 100
      elsif days_until_due <= 7
        score += 75
      elsif days_until_due <= 14
        score += 50
      end
    end
    
    # Task type scoring
    case task.task_type
    when 'legal' then score += 50
    when 'financial' then score += 40
    when 'technical' then score += 30
    when 'administrative' then score += 20
    when 'quality_control' then score += 10
    end
    
    # Dependencies scoring
    score += task.dependent_tasks.count * 10
    
    score
  end
  
  def calculate_delays
    delays = {
      phases: [],
      tasks: [],
      milestones: []
    }
    
    # Check delayed phases
    project.phases.each do |phase|
      if phase.is_delayed?
        delays[:phases] << phase
      end
    end
    
    # Check delayed tasks
    project.phases.joins(:tasks).includes(:tasks).each do |phase|
      phase.tasks.each do |task|
        if task.is_overdue?
          delays[:tasks] << task
        end
      end
    end
    
    # Check delayed milestones
    Immo::Promo::Milestone.joins(:phase)
                          .where(phase: { project_id: project.id })
                          .where('target_date < ? AND immo_promo_milestones.status != ?', Date.current, 'completed')
                          .each do |milestone|
      delays[:milestones] << milestone
    end
    
    delays
  end
end