# Concern for project-specific calculations in ImmoPromo
module ProjectCalculable
  extend ActiveSupport::Concern
  
  # Include the main calculable concern
  include ::Calculable

  # Calculate overall project progress
  def calculate_project_progress(project)
    phases = project.phases.includes(:tasks)
    return 0.0 if phases.empty?
    
    phase_progresses = phases.map do |phase|
      phase_progress = calculate_phase_progress(phase)
      weight = phase.weight || 1.0
      { progress: phase_progress, weight: weight }
    end
    
    calculate_weighted_average(phase_progresses.map { |p| [p[:progress], p[:weight]] })
  end

  # Calculate phase progress based on tasks
  def calculate_phase_progress(phase)
    tasks = phase.tasks
    return 0.0 if tasks.empty?
    
    completed_tasks = tasks.count(&:completed?)
    calculate_percentage(completed_tasks, tasks.count)
  end

  # Calculate budget progress
  def calculate_budget_progress(project)
    total_budget = project.budget_amount || 0
    return 0.0 if total_budget.zero?
    
    spent_amount = project.budget_lines.sum(:amount) || 0
    calculate_percentage(spent_amount, total_budget)
  end

  # Calculate timeline progress
  def calculate_timeline_progress(project)
    return 0.0 unless project.start_date && project.end_date
    
    calculate_time_progress(project.start_date, project.end_date)
  end

  # Calculate project delay in days
  def calculate_project_delay(project)
    return 0 unless project.end_date
    
    actual_progress = calculate_project_progress(project)
    timeline_progress = calculate_timeline_progress(project)
    
    if actual_progress < timeline_progress
      total_duration = (project.end_date - project.start_date).to_i
      delay_percentage = timeline_progress - actual_progress
      (total_duration * delay_percentage / 100).round
    else
      0
    end
  end

  # Calculate estimated completion date
  def calculate_estimated_completion(project)
    return project.end_date unless project.start_date && project.end_date
    
    current_progress = calculate_project_progress(project)
    return project.end_date if current_progress >= 100
    
    elapsed_days = (Date.current - project.start_date).to_i
    return project.end_date if elapsed_days <= 0
    
    # Calculate velocity (progress per day)
    velocity = current_progress / elapsed_days.to_f
    return project.end_date if velocity <= 0
    
    # Estimate remaining days
    remaining_progress = 100 - current_progress
    remaining_days = (remaining_progress / velocity).ceil
    
    Date.current + remaining_days.days
  end

  # Calculate critical path duration
  def calculate_critical_path(project)
    phases = project.phases.includes(:tasks).order(:position)
    return 0 if phases.empty?
    
    critical_duration = 0
    
    phases.each do |phase|
      phase_duration = calculate_phase_duration(phase)
      critical_duration += phase_duration
    end
    
    critical_duration
  end

  # Calculate phase duration in business days
  def calculate_phase_duration(phase)
    return 0 unless phase.start_date && phase.end_date
    
    calculate_business_days(phase.start_date, phase.end_date)
  end

  # Calculate resource utilization for project
  def calculate_resource_utilization(project)
    allocations = project.stakeholder_allocations.includes(:stakeholder)
    return {} if allocations.empty?
    
    utilization = {}
    
    allocations.group_by(&:stakeholder).each do |stakeholder, stakeholder_allocations|
      total_hours = stakeholder_allocations.sum(&:allocated_hours) || 0
      worked_hours = stakeholder_allocations.sum(&:actual_hours) || 0
      
      utilization[stakeholder.id] = {
        stakeholder: stakeholder,
        total_hours: total_hours,
        worked_hours: worked_hours,
        utilization_rate: calculate_percentage(worked_hours, total_hours),
        efficiency: calculate_efficiency(stakeholder_allocations)
      }
    end
    
    utilization
  end

  # Calculate cost performance index (CPI)
  def calculate_cost_performance_index(project)
    earned_value = calculate_earned_value(project)
    actual_cost = calculate_actual_cost(project)
    
    return 1.0 if actual_cost.zero?
    earned_value / actual_cost
  end

  # Calculate schedule performance index (SPI)
  def calculate_schedule_performance_index(project)
    earned_value = calculate_earned_value(project)
    planned_value = calculate_planned_value(project)
    
    return 1.0 if planned_value.zero?
    earned_value / planned_value
  end

  # Calculate project ROI
  def calculate_project_roi(project)
    total_revenue = project.estimated_revenue || 0
    total_cost = calculate_total_project_cost(project)
    
    return 0.0 if total_cost.zero?
    calculate_percentage(total_revenue - total_cost, total_cost)
  end

  private

  def calculate_efficiency(allocations)
    return 0.0 if allocations.empty?
    
    efficiency_scores = allocations.map do |allocation|
      next 0.0 unless allocation.allocated_hours&.positive?
      
      # Efficiency = (Planned Hours / Actual Hours) * Quality Score
      planned_hours = allocation.allocated_hours
      actual_hours = allocation.actual_hours || planned_hours
      quality_score = allocation.quality_score || 1.0
      
      (planned_hours / actual_hours.to_f) * quality_score
    end.compact
    
    return 0.0 if efficiency_scores.empty?
    efficiency_scores.sum / efficiency_scores.size
  end

  def calculate_earned_value(project)
    progress = calculate_project_progress(project)
    budget = project.budget_amount || 0
    
    (progress / 100.0) * budget
  end

  def calculate_actual_cost(project)
    project.budget_lines.sum(:amount) || 0
  end

  def calculate_planned_value(project)
    timeline_progress = calculate_timeline_progress(project)
    budget = project.budget_amount || 0
    
    (timeline_progress / 100.0) * budget
  end

  def calculate_total_project_cost(project)
    # Include all costs: budget lines, resources, overhead
    budget_cost = project.budget_lines.sum(:amount) || 0
    resource_cost = calculate_resource_cost(project)
    overhead_cost = calculate_overhead_cost(project)
    
    budget_cost + resource_cost + overhead_cost
  end

  def calculate_resource_cost(project)
    # Calculate cost of human resources
    allocations = project.stakeholder_allocations
    
    allocations.sum do |allocation|
      hours = allocation.actual_hours || allocation.allocated_hours || 0
      rate = allocation.stakeholder.hourly_rate || 0
      hours * rate
    end
  end

  def calculate_overhead_cost(project)
    # Calculate overhead (typically a percentage of direct costs)
    direct_costs = calculate_actual_cost(project)
    overhead_rate = project.overhead_rate || 0.15 # 15% default
    
    direct_costs * overhead_rate
  end
end