class Immo::Promo::StakeholderCoordinatorService
  attr_reader :project, :current_user

  def initialize(project, current_user)
    @project = project
    @current_user = current_user
  end

  def coordinate_interventions
    coordination_plan = []
    
    # Group tasks by phase and analyze dependencies
    project.phases.includes(:tasks).order(:position).each do |phase|
      phase_coordination = coordinate_phase_interventions(phase)
      coordination_plan << phase_coordination if phase_coordination[:tasks].any?
    end
    
    coordination_plan
  end

  def validate_stakeholder_qualifications
    qualification_issues = []
    
    project.stakeholders.active.each do |stakeholder|
      issues = check_stakeholder_qualifications(stakeholder)
      qualification_issues.concat(issues) if issues.any?
    end
    
    qualification_issues.sort_by { |issue| issue[:severity] == 'critical' ? 0 : 1 }
  end

  def optimize_team_allocation
    optimization_recommendations = []
    
    # Analyze workload distribution
    overloaded_stakeholders = find_overloaded_stakeholders
    underutilized_stakeholders = find_underutilized_stakeholders
    
    # Generate rebalancing recommendations
    if overloaded_stakeholders.any? && underutilized_stakeholders.any?
      optimization_recommendations.concat(
        generate_rebalancing_recommendations(overloaded_stakeholders, underutilized_stakeholders)
      )
    end
    
    # Check for skill gaps
    skill_gaps = identify_skill_gaps
    optimization_recommendations.concat(skill_gaps) if skill_gaps.any?
    
    # Check for redundancies
    redundancies = identify_redundancies
    optimization_recommendations.concat(redundancies) if redundancies.any?
    
    optimization_recommendations
  end

  def track_stakeholder_communications
    communication_summary = {
      recent_interactions: [],
      pending_responses: [],
      escalation_needed: []
    }
    
    # This would integrate with a communication system
    # For now, we'll use task assignments and updates as proxy
    
    # Recent task assignments and completions
    recent_tasks = project.tasks.includes(:assigned_to, :stakeholder, :phase)
                          .where('updated_at > ?', 1.week.ago)
                          .order(updated_at: :desc)
                          .limit(20)
    
    recent_tasks.each do |task|
      communication_summary[:recent_interactions] << {
        type: task.status_was != task.status ? 'status_update' : 'assignment',
        stakeholder: task.stakeholder,
        assigned_user: task.assigned_to,
        task: task,
        timestamp: task.updated_at,
        phase: task.phase
      }
    end
    
    # Find tasks with no recent updates (potential non-responses)
    stale_tasks = project.tasks.includes(:assigned_to, :stakeholder, :phase)
                         .where(status: ['pending', 'in_progress'])
                         .where('updated_at < ?', 3.days.ago)
                         .order(:updated_at)
    
    stale_tasks.each do |task|
      communication_summary[:pending_responses] << {
        task: task,
        stakeholder: task.stakeholder,
        assigned_user: task.assigned_to,
        days_since_update: (Date.current - task.updated_at.to_date).to_i,
        phase: task.phase
      }
    end
    
    # Find overdue tasks that need escalation
    overdue_tasks = project.tasks.overdue.includes(:assigned_to, :stakeholder, :phase)
    
    overdue_tasks.each do |task|
      communication_summary[:escalation_needed] << {
        task: task,
        stakeholder: task.stakeholder,
        assigned_user: task.assigned_to,
        days_overdue: (Date.current - task.end_date.to_date).to_i,
        phase: task.phase,
        escalation_level: determine_escalation_level(task)
      }
    end
    
    communication_summary
  end

  def generate_stakeholder_directory
    directory = {}
    
    project.stakeholders.active.includes(:certifications, :contracts).each do |stakeholder|
      directory[stakeholder.stakeholder_type] ||= []
      directory[stakeholder.stakeholder_type] << {
        stakeholder: stakeholder,
        contact_info: stakeholder.contact_info,
        qualifications: stakeholder.certifications.valid.pluck(:name),
        active_contracts: stakeholder.active_contracts.count,
        current_tasks: stakeholder.tasks.where(status: ['pending', 'in_progress']).count,
        specializations: determine_specializations(stakeholder),
        availability_status: determine_availability_status(stakeholder),
        performance_rating: calculate_performance_rating(stakeholder)
      }
    end
    
    directory
  end

  private

  def coordinate_phase_interventions(phase)
    {
      phase: phase,
      tasks: phase.tasks.includes(:stakeholder, :assigned_to).map do |task|
        {
          task: task,
          stakeholder: task.stakeholder,
          assigned_user: task.assigned_to,
          dependencies: task.prerequisite_tasks.pluck(:name),
          coordination_notes: generate_coordination_notes(task),
          scheduling_constraints: identify_scheduling_constraints(task)
        }
      end,
      coordination_meetings: suggest_coordination_meetings(phase),
      potential_conflicts: identify_potential_conflicts(phase)
    }
  end

  def check_stakeholder_qualifications(stakeholder)
    issues = []
    
    # Check insurance validity
    unless stakeholder.has_valid_insurance?
      issues << {
        stakeholder: stakeholder,
        type: 'insurance',
        severity: 'critical',
        message: 'Assurance responsabilité civile manquante ou expirée',
        action: 'Fournir une attestation d\'assurance valide'
      }
    end
    
    # Check professional qualifications
    unless stakeholder.has_valid_qualification?
      issues << {
        stakeholder: stakeholder,
        type: 'qualification',
        severity: 'high',
        message: 'Qualifications professionnelles manquantes ou expirées',
        action: 'Fournir les certifications professionnelles requises'
      }
    end
    
    # Check specific requirements based on stakeholder type
    case stakeholder.stakeholder_type
    when 'contractor', 'subcontractor'
      unless has_construction_qualifications?(stakeholder)
        issues << {
          stakeholder: stakeholder,
          type: 'construction_qualification',
          severity: 'high',
          message: 'Qualifications de construction manquantes',
          action: 'Obtenir les certifications RGE ou Qualibat nécessaires'
        }
      end
    when 'architect'
      unless has_architecture_registration?(stakeholder)
        issues << {
          stakeholder: stakeholder,
          type: 'registration',
          severity: 'critical',
          message: 'Inscription à l\'ordre des architectes manquante',
          action: 'Fournir l\'attestation d\'inscription à l\'ordre'
        }
      end
    end
    
    issues
  end

  def find_overloaded_stakeholders
    project.stakeholders.active.select do |stakeholder|
      active_tasks = stakeholder.tasks.where(status: ['pending', 'in_progress']).count
      estimated_hours = stakeholder.tasks.where(status: ['pending', 'in_progress']).sum(:estimated_hours) || 0
      
      active_tasks > 5 || estimated_hours > 40
    end
  end

  def find_underutilized_stakeholders
    project.stakeholders.active.select do |stakeholder|
      active_tasks = stakeholder.tasks.where(status: ['pending', 'in_progress']).count
      estimated_hours = stakeholder.tasks.where(status: ['pending', 'in_progress']).sum(:estimated_hours) || 0
      
      active_tasks < 2 && estimated_hours < 20
    end
  end

  def generate_rebalancing_recommendations(overloaded, underutilized)
    recommendations = []
    
    overloaded.each do |overloaded_stakeholder|
      # Find tasks that could be reassigned
      reassignable_tasks = overloaded_stakeholder.tasks
                                                .where(status: ['pending'])
                                                .where('start_date > ?', Date.current)
      
      reassignable_tasks.each do |task|
        suitable_alternatives = find_suitable_alternatives(task, underutilized)
        
        if suitable_alternatives.any?
          recommendations << {
            type: 'task_reassignment',
            from_stakeholder: overloaded_stakeholder,
            to_stakeholder: suitable_alternatives.first,
            task: task,
            reason: 'Rééquilibrage de la charge de travail',
            estimated_impact: 'Réduction du risque de retard'
          }
        end
      end
    end
    
    recommendations
  end

  def identify_skill_gaps
    skill_gaps = []
    
    # Analyze required skills vs available stakeholders
    required_skills = project.tasks.where(status: ['pending', 'in_progress'])
                             .group(:task_type)
                             .count
    
    available_skills = project.stakeholders.active
                              .group(:stakeholder_type)
                              .count
    
    required_skills.each do |skill, count|
      corresponding_stakeholder_type = map_task_to_stakeholder_type(skill)
      available_count = available_skills[corresponding_stakeholder_type] || 0
      
      if available_count == 0
        skill_gaps << {
          type: 'missing_skill',
          skill: skill,
          urgency: 'critical',
          recommendation: "Recruter un #{corresponding_stakeholder_type.humanize}"
        }
      elsif count > available_count * 3 # Arbitrary threshold
        skill_gaps << {
          type: 'insufficient_capacity',
          skill: skill,
          urgency: 'medium',
          current_capacity: available_count,
          required_capacity: count,
          recommendation: "Ajouter des ressources en #{skill.humanize}"
        }
      end
    end
    
    skill_gaps
  end

  def identify_redundancies
    redundancies = []
    
    # Group stakeholders by type and analyze utilization
    project.stakeholders.active.group_by(&:stakeholder_type).each do |type, stakeholders|
      if stakeholders.count > 1
        utilization_rates = stakeholders.map do |stakeholder|
          task_count = stakeholder.tasks.where(status: ['pending', 'in_progress']).count
          { stakeholder: stakeholder, utilization: task_count }
        end
        
        underutilized = utilization_rates.select { |ur| ur[:utilization] == 0 }
        
        if underutilized.count > 1
          redundancies << {
            type: 'stakeholder_redundancy',
            stakeholder_type: type,
            redundant_stakeholders: underutilized.map { |ur| ur[:stakeholder] },
            recommendation: 'Considérer la réduction du nombre d\'intervenants de ce type'
          }
        end
      end
    end
    
    redundancies
  end

  def determine_escalation_level(task)
    days_overdue = (Date.current - task.end_date.to_date).to_i
    
    case days_overdue
    when 0..3 then 'low'
    when 4..7 then 'medium'
    when 8..14 then 'high'
    else 'critical'
    end
  end

  def determine_specializations(stakeholder)
    # Analyze completed tasks to determine specializations
    completed_tasks = stakeholder.tasks.where(status: 'completed')
    task_types = completed_tasks.group(:task_type).count
    
    task_types.keys
  end

  def determine_availability_status(stakeholder)
    active_tasks = stakeholder.tasks.where(status: ['pending', 'in_progress']).count
    
    case active_tasks
    when 0 then 'available'
    when 1..3 then 'partially_available'
    when 4..6 then 'busy'
    else 'overloaded'
    end
  end

  def calculate_performance_rating(stakeholder)
    # Simple performance calculation based on task completion
    completed_tasks = stakeholder.tasks.where(status: 'completed')
    return 'N/A' if completed_tasks.empty?
    
    on_time_tasks = completed_tasks.select do |task|
      task.actual_end_date && task.end_date && 
      task.actual_end_date <= task.end_date
    end
    
    performance_ratio = on_time_tasks.count.to_f / completed_tasks.count
    
    case performance_ratio
    when 0.9..1.0 then 'excellent'
    when 0.8..0.89 then 'good'
    when 0.7..0.79 then 'average'
    when 0.6..0.69 then 'below_average'
    else 'poor'
    end
  end

  def generate_coordination_notes(task)
    notes = []
    
    # Check for dependency conflicts
    if task.prerequisite_tasks.any? { |pt| pt.end_date && pt.end_date > task.start_date }
      notes << 'Attention: conflit de planning avec les tâches prérequises'
    end
    
    # Check for resource conflicts
    if task.assigned_to && task.stakeholder
      concurrent_tasks = task.assigned_to.tasks
                            .where(status: ['pending', 'in_progress'])
                            .where.not(id: task.id)
                            .where('start_date <= ? AND end_date >= ?', task.end_date, task.start_date)
      
      if concurrent_tasks.any?
        notes << "Conflit potentiel: #{concurrent_tasks.count} autres tâches en parallèle"
      end
    end
    
    notes
  end

  def identify_scheduling_constraints(task)
    constraints = []
    
    # Weather constraints
    if task.task_type == 'technical' && ['construction'].include?(task.phase.phase_type)
      if task.start_date && [12, 1, 2].include?(task.start_date.month)
        constraints << 'Contrainte météorologique: période hivernale'
      end
    end
    
    # Regulatory constraints
    if task.task_type == 'legal'
      constraints << 'Délais réglementaires d\'instruction à respecter'
    end
    
    # Resource availability constraints
    if task.stakeholder && !task.stakeholder.is_active
      constraints << 'Intervenant actuellement indisponible'
    end
    
    constraints
  end

  def suggest_coordination_meetings(phase)
    meetings = []
    
    # Suggest kick-off meeting for new phases
    if phase.pending? && phase.start_date && phase.start_date <= 2.weeks.from_now
      meetings << {
        type: 'kick_off',
        suggested_date: phase.start_date - 1.week,
        participants: phase.tasks.includes(:stakeholder, :assigned_to)
                           .map { |t| [t.stakeholder, t.assigned_to] }
                           .flatten.compact.uniq,
        agenda: ['Présentation de la phase', 'Coordination des interventions', 'Planning détaillé']
      }
    end
    
    # Suggest weekly coordination meetings for active phases
    if phase.in_progress?
      meetings << {
        type: 'weekly_coordination',
        suggested_date: Date.current.next_occurring(:monday),
        participants: phase.tasks.where(status: ['pending', 'in_progress'])
                           .includes(:stakeholder, :assigned_to)
                           .map { |t| [t.stakeholder, t.assigned_to] }
                           .flatten.compact.uniq,
        agenda: ['Point d\'avancement', 'Résolution des blocages', 'Planning de la semaine']
      }
    end
    
    meetings
  end

  def identify_potential_conflicts(phase)
    conflicts = []
    
    # Resource conflicts
    resource_usage = {}
    phase.tasks.includes(:assigned_to).each do |task|
      next unless task.assigned_to && task.start_date && task.end_date
      
      (task.start_date.to_date..task.end_date.to_date).each do |date|
        resource_usage[date] ||= []
        resource_usage[date] << { task: task, user: task.assigned_to }
      end
    end
    
    resource_usage.each do |date, assignments|
      user_assignments = assignments.group_by { |a| a[:user] }
      user_assignments.each do |user, user_tasks|
        if user_tasks.count > 1
          conflicts << {
            type: 'resource_conflict',
            date: date,
            user: user,
            conflicting_tasks: user_tasks.map { |ut| ut[:task] },
            severity: user_tasks.count > 2 ? 'high' : 'medium'
          }
        end
      end
    end
    
    conflicts
  end

  def find_suitable_alternatives(task, candidates)
    candidates.select do |candidate|
      # Check if stakeholder type is compatible
      compatible_types = compatible_stakeholder_types(task.task_type)
      compatible_types.include?(candidate.stakeholder_type) &&
      # Check availability during task period
      !has_conflicting_tasks?(candidate, task) &&
      # Check qualifications
      candidate.has_valid_qualification?
    end
  end

  def map_task_to_stakeholder_type(task_type)
    case task_type
    when 'technical' then 'engineer'
    when 'administrative' then 'consultant'
    when 'legal' then 'legal_advisor'
    when 'financial' then 'consultant'
    when 'quality_control' then 'control_office'
    else 'contractor'
    end
  end

  def compatible_stakeholder_types(task_type)
    case task_type
    when 'technical' then ['engineer', 'architect', 'contractor']
    when 'administrative' then ['consultant', 'legal_advisor']
    when 'legal' then ['legal_advisor', 'consultant']
    when 'financial' then ['consultant']
    when 'quality_control' then ['control_office', 'engineer']
    else ['contractor', 'subcontractor']
    end
  end

  def has_conflicting_tasks?(stakeholder, task)
    return false unless task.start_date && task.end_date
    
    stakeholder.tasks.where(status: ['pending', 'in_progress'])
              .where('start_date <= ? AND end_date >= ?', task.end_date, task.start_date)
              .exists?
  end

  def has_construction_qualifications?(stakeholder)
    stakeholder.certifications.where(
      certification_type: ['qualification', 'rge'],
      is_valid: true
    ).exists?
  end

  def has_architecture_registration?(stakeholder)
    stakeholder.certifications.where(
      certification_type: 'qualification',
      name: ['Ordre des Architectes', 'DPLG', 'HMONP'],
      is_valid: true
    ).exists?
  end
end