module Immo
  module Promo
    class ProjectResourceService
      attr_reader :project, :capacity_service, :optimization_service, :skills_service

      def initialize(project)
        @project = project
        @capacity_service = ResourceCapacityService.new(project)
        @optimization_service = ResourceOptimizationService.new(project)
        @skills_service = ResourceSkillsService.new(project)
      end

      def resource_allocation_summary
        {
          stakeholders: stakeholder_allocation_summary,
          by_phase: resource_allocation_by_phase,
          utilization_metrics: calculate_utilization_metrics,
          conflicts: identify_resource_conflicts,
          recommendations: optimization_recommendations
        }
      end

      def stakeholder_workload_analysis
        project.stakeholders.includes(:tasks).map do |stakeholder|
          tasks = stakeholder.tasks.includes(:phase)
          
          {
            stakeholder: stakeholder_summary(stakeholder),
            workload: calculate_stakeholder_workload(stakeholder),
            tasks: task_load_details(tasks),
            availability: calculate_availability(stakeholder),
            efficiency_metrics: calculate_efficiency_metrics(stakeholder)
          }
        end
      end

      def optimize_task_assignments
        @optimization_service.optimize_assignments
      end

      def resource_capacity_planning
        @capacity_service.analyze_capacity
      end

      def skill_matrix_analysis
        @skills_service.analyze_skills_matrix
      end

      def resource_allocation_summary
        workload = stakeholder_workload_analysis
        optimization = optimize_task_assignments
        capacity = resource_capacity_planning
        
        conflicts = []
        
        # Check for overallocation
        overloaded = workload.find_all { |w| 
          percentage = w[:workload][:workload_percentage]
          percentage && percentage > 100 
        }
        if overloaded.any?
          conflicts << {
            type: 'overallocation',
            severity: 'high',
            affected_stakeholders: overloaded.map { |w| w[:stakeholder][:name] },
            description: "#{overloaded.count} stakeholders are overallocated"
          }
        end
        
        # Check for underutilization
        underutilized = workload.find_all { |w| 
          percentage = w[:workload][:workload_percentage]
          percentage && percentage < 50 
        }
        if underutilized.any?
          conflicts << {
            type: 'underutilization',
            severity: 'medium',
            affected_stakeholders: underutilized.map { |w| w[:stakeholder][:name] },
            description: "#{underutilized.count} stakeholders are underutilized"
          }
        end
        
        # Build stakeholders summary
        stakeholders_summary = {
          total: project.stakeholders.count,
          by_status: project.stakeholders.group_by { |s| s.is_active ? 'active' : 'inactive' }.transform_values(&:count),
          by_type: project.stakeholders.group(:stakeholder_type).count,
          overloaded: overloaded.count,
          available: project.stakeholders.count - overloaded.count
        }
        
        # Build phase allocation data
        phase_allocation = project.phases.map do |phase|
          tasks = phase.tasks
          allocated_stakeholders = tasks.map(&:stakeholder_id).compact.uniq
          
          {
            phase: phase.name,
            status: phase.status,
            resource_count: allocated_stakeholders.count,
            total_hours: tasks.sum(:estimated_hours),
            workload_distribution: tasks.group(:priority).count,
            phase_id: phase.id,
            phase_type: phase.phase_type,
            total_tasks: tasks.count,
            completion_percentage: phase.completion_percentage
          }
        end
        
        # Build utilization metrics
        utilizations = workload.map { |w| w[:workload][:utilization_percentage] || 0 }
        utilization_metrics = {
          average_utilization: utilizations.any? ? (utilizations.sum / utilizations.size.to_f).round(2) : 0,
          min_utilization: utilizations.min || 0,
          max_utilization: utilizations.max || 0,
          standard_deviation: calculate_standard_deviation(utilizations),
          efficiency_index: capacity[:current_capacity][:utilization_rate] || 0
        }
        
        # Check for skill mismatches
        skill_gaps = @skills_service.analyze_skills_matrix[:skill_gaps] || []
        if skill_gaps.any?
          conflicts << {
            type: 'skill_mismatch',
            severity: 'medium',
            skill_gaps: skill_gaps,
            description: "#{skill_gaps.count} required skills are missing"
          }
        end
        
        # Build recommendations
        recommendations = []
        recommendations << "Consider redistributing tasks from overloaded resources" if overloaded.any?
        recommendations << "Consider assigning more tasks to underutilized resources" if underutilized.any?
        recommendations.concat(capacity[:recommendations] || [])
        
        {
          stakeholders: stakeholders_summary,
          by_phase: phase_allocation,
          utilization_metrics: utilization_metrics,
          conflicts: conflicts,
          recommendations: recommendations,
          current_allocation: workload,
          optimization_suggestions: optimization,
          capacity_analysis: capacity
        }
      end
      
      def resource_conflict_calendar
        conflicts = []
        
        project.stakeholders.each do |stakeholder|
          stakeholder_conflicts = find_scheduling_conflicts(stakeholder)
          
          if stakeholder_conflicts.any?
            conflicts << {
              stakeholder: stakeholder,
              conflicts: stakeholder_conflicts,
              impact: assess_conflict_impact(stakeholder_conflicts)
            }
          end
        end
        
        {
          total_conflicts: conflicts.sum { |c| c[:conflicts].count },
          affected_resources: conflicts.count,
          conflicts_by_resource: conflicts,
          resolution_suggestions: generate_conflict_resolutions(conflicts)
        }
      end

      private

      def stakeholder_summary(stakeholder)
        {
          id: stakeholder.id,
          name: stakeholder.name,
          type: stakeholder.stakeholder_type,
          status: stakeholder.is_active ? 'active' : 'inactive',
          performance_rating: stakeholder.performance_rating
        }
      end

      def calculate_stakeholder_workload(assignee)
        # Handle both stakeholders and users
        if assignee.is_a?(Immo::Promo::Stakeholder)
          active_tasks = assignee.tasks.where(status: ['in_progress', 'pending'])
          completed_tasks = assignee.tasks.where(status: 'completed')
        else
          # For users, find tasks in this project
          active_tasks = @project.tasks.where(assigned_to: assignee, status: ['in_progress', 'pending'])
          completed_tasks = @project.tasks.where(assigned_to: assignee, status: 'completed')
        end
        
        total_hours = active_tasks.sum(:estimated_hours)
        utilization = assignee.is_a?(Immo::Promo::Stakeholder) ? calculate_utilization_percentage(assignee) : 0
        
        {
          active_tasks: active_tasks.count,
          completed_tasks: completed_tasks.count,
          total_hours_allocated: total_hours,
          hours_completed: completed_tasks.sum(:actual_hours) || 0,
          utilization_percentage: utilization,
          workload_percentage: utilization  # Ajouter aussi workload_percentage pour compatibilité
        }
      end

      def task_load_details(tasks)
        tasks.group_by(&:status).transform_values do |status_tasks|
          {
            count: status_tasks.count,
            total_hours: status_tasks.sum(&:estimated_hours),
            tasks: status_tasks.map { |t| 
              {
                id: t.id,
                name: t.name,
                phase: t.phase.name,
                priority: t.priority,
                estimated_hours: t.estimated_hours
              }
            }
          }
        end
      end

      def calculate_availability(stakeholder)
        total_capacity = 40 # hours per week
        allocated_hours = calculate_weekly_allocated_hours(stakeholder)
        
        {
          total_capacity: total_capacity,
          allocated_hours: allocated_hours,
          available_hours: total_capacity - allocated_hours,
          availability_percentage: ((total_capacity - allocated_hours) / total_capacity.to_f * 100).round(2),
          status: resource_status(allocated_hours / total_capacity.to_f * 100)
        }
      end

      def calculate_weekly_allocated_hours(stakeholder)
        active_tasks = stakeholder.tasks.where(status: ['in_progress', 'pending'])
        return 0 if active_tasks.empty?
        
        weeks_remaining = @capacity_service.send(:calculate_weeks_remaining)
        return 40 if weeks_remaining == 0
        
        total_hours = active_tasks.sum(:estimated_hours)
        (total_hours.to_f / weeks_remaining).round(2)
      end

      def calculate_efficiency_metrics(stakeholder)
        completed_tasks = stakeholder.tasks.where(status: 'completed')
        
        return default_efficiency_metrics if completed_tasks.empty?
        
        on_time_tasks = completed_tasks.select { |t| t.actual_end_date && t.end_date && t.actual_end_date <= t.end_date }
        
        {
          tasks_completed: completed_tasks.count,
          on_time_delivery_rate: (on_time_tasks.count.to_f / completed_tasks.count * 100).round(2),
          average_task_duration: calculate_average_task_duration(completed_tasks),
          efficiency_score: calculate_efficiency_score(stakeholder)
        }
      end

      def default_efficiency_metrics
        {
          tasks_completed: 0,
          on_time_delivery_rate: 0,
          average_task_duration: 0,
          efficiency_score: 0
        }
      end

      def calculate_average_task_duration(tasks)
        durations = tasks.map do |task|
          next unless task.actual_start_date && task.actual_end_date
          (task.actual_end_date - task.actual_start_date).to_i
        end.compact
        
        return 0 if durations.empty?
        durations.sum / durations.count.to_f
      end

      def calculate_efficiency_score(stakeholder)
        # Simple efficiency score based on performance rating
        case stakeholder.performance_rating
        when 'excellent' then 95
        when 'good' then 85
        when 'average' then 75
        when 'below_average' then 65
        else 70
        end
      end

      def stakeholder_allocation_summary
        stakeholders = project.stakeholders.active
        
        grouped = stakeholders.group_by { |s| resource_status(calculate_utilization_percentage(s)) }
        
        {
          total: stakeholders.count,
          by_status: grouped.transform_values(&:count),
          by_type: stakeholders.group_by(&:stakeholder_type).transform_values(&:count),
          overloaded: grouped['overloaded'] || [],
          available: grouped['available'] || []
        }
      end

      def resource_status(utilization)
        case utilization
        when 0..30 then 'available'
        when 31..70 then 'partially_allocated'
        when 71..100 then 'fully_allocated'
        else 'overloaded'
        end
      end

      def resource_allocation_by_phase
        project.phases.includes(:tasks).map do |phase|
          tasks = phase.tasks.includes(:stakeholder)
          
          {
            phase: phase.name,
            status: phase.status,
            resource_count: tasks.map(&:stakeholder).uniq.compact.count,
            total_hours: tasks.sum(&:estimated_hours),
            workload_distribution: calculate_phase_workload_distribution(tasks)
          }
        end
      end

      def calculate_phase_workload_distribution(tasks)
        tasks.group_by(&:stakeholder).transform_values do |stakeholder_tasks|
          {
            task_count: stakeholder_tasks.count,
            total_hours: stakeholder_tasks.sum(&:estimated_hours)
          }
        end
      end

      def calculate_utilization_metrics
        stakeholders = project.stakeholders.active
        utilizations = stakeholders.map { |s| calculate_utilization_percentage(s) }
        
        {
          average_utilization: utilizations.sum / utilizations.count.to_f,
          min_utilization: utilizations.min,
          max_utilization: utilizations.max,
          standard_deviation: calculate_standard_deviation(utilizations),
          efficiency_index: calculate_resource_efficiency
        }
      end

      def calculate_standard_deviation(values)
        return 0 if values.empty?
        
        mean = values.sum / values.count.to_f
        variance = values.sum { |v| (v - mean) ** 2 } / values.count.to_f
        Math.sqrt(variance)
      end

      def calculate_resource_efficiency
        # Efficiency based on balanced utilization
        utilizations = project.stakeholders.active.map { |s| calculate_utilization_percentage(s) }
        
        optimal_range = utilizations.count { |u| u.between?(70, 90) }
        total = utilizations.count
        
        return 0 if total == 0
        (optimal_range.to_f / total * 100).round(2)
      end

      def identify_resource_conflicts
        conflicts = []
        
        # Overallocation conflicts
        overloaded = project.stakeholders.select { |s| calculate_utilization_percentage(s) > 100 }
        if overloaded.any?
          conflicts << {
            type: 'overallocation',
            severity: 'high',
            resources: overloaded,
            message: "#{overloaded.count} resources are overallocated"
          }
        end
        
        # Skill mismatch conflicts
        skill_mismatches = identify_skill_mismatches
        if skill_mismatches.any?
          conflicts << {
            type: 'skill_mismatch',
            severity: 'medium',
            count: skill_mismatches.count,
            message: "#{skill_mismatches.count} tasks assigned to resources without required skills"
          }
        end
        
        # Availability conflicts
        availability_conflicts = identify_availability_conflicts
        if availability_conflicts.any?
          conflicts << {
            type: 'availability',
            severity: 'high',
            count: availability_conflicts.count,
            message: "#{availability_conflicts.count} resources have scheduling conflicts"
          }
        end
        
        conflicts
      end

      def calculate_utilization_percentage(stakeholder)
        allocated_hours = calculate_allocated_hours(stakeholder)
        # Base sur 40 heures par semaine
        weekly_capacity = 40
        
        # Si le stakeholder a plus d'heures allouées que sa capacité hebdomadaire,
        # calculer le pourcentage basé sur sa charge actuelle
        (allocated_hours.to_f / weekly_capacity * 100).round(2)
      end

      def calculate_allocated_hours(stakeholder)
        stakeholder.tasks
                   .where(status: ['in_progress', 'pending'])
                   .sum(:estimated_hours)
      end

      def identify_skill_mismatches
        mismatches = []
        
        project.tasks.includes(:stakeholder).where.not(stakeholder_id: nil).each do |task|
          next if task.required_skills.blank?
          
          stakeholder_skills = task.stakeholder.certifications.pluck(:certification_type)
          missing_skills = task.required_skills - stakeholder_skills
          
          if missing_skills.any?
            mismatches << {
              task: task,
              stakeholder: task.stakeholder,
              missing_skills: missing_skills
            }
          end
        end
        
        mismatches
      end

      def identify_availability_conflicts
        conflicts = []
        
        project.stakeholders.each do |stakeholder|
          overlapping_tasks = find_overlapping_tasks(stakeholder)
          
          if overlapping_tasks.any?
            conflicts << {
              stakeholder: stakeholder,
              overlapping_tasks: overlapping_tasks
            }
          end
        end
        
        conflicts
      end

      def find_overlapping_tasks(stakeholder)
        tasks = stakeholder.tasks
                          .where(status: ['in_progress', 'pending'])
                          .where.not(start_date: nil, end_date: nil)
                          .order(:start_date)
        
        overlapping = []
        
        tasks.each_with_index do |task, index|
          tasks[(index + 1)..-1].each do |other_task|
            if tasks_overlap?(task, other_task)
              overlapping << [task, other_task]
            end
          end
        end
        
        overlapping
      end

      def tasks_overlap?(task1, task2)
        task1.start_date <= task2.end_date && task1.end_date >= task2.start_date
      end

      def optimization_recommendations
        recommendations = []
        
        # Load balancing
        if needs_load_balancing?
          recommendations << {
            type: 'load_balancing',
            priority: 'high',
            action: 'Redistribute tasks from overloaded to available resources',
            impact: 'Improve delivery timeline and resource satisfaction'
          }
        end
        
        # Skill optimization
        skill_gaps = @skills_service.identify_skill_gaps
        if skill_gaps.any? { |g| g[:severity] == 'critical' }
          recommendations << {
            type: 'skill_acquisition',
            priority: 'urgent',
            action: 'Acquire missing critical skills through hiring or training',
            impact: 'Enable project continuation'
          }
        end
        
        # Capacity recommendations
        capacity_recs = @capacity_service.capacity_recommendations
        recommendations.concat(capacity_recs)
        
        recommendations.sort_by { |r| priority_sort_value(r[:priority]) }
      end

      def needs_load_balancing?
        utilizations = project.stakeholders.active.map { |s| calculate_utilization_percentage(s) }
        
        return false if utilizations.empty?
        
        # Check if there's significant imbalance
        utilizations.max - utilizations.min > 50
      end

      def priority_sort_value(priority)
        case priority
        when 'urgent' then 1
        when 'high' then 2
        when 'medium' then 3
        else 4
        end
      end

      def calculate_standard_deviation(values)
        return 0 if values.empty? || values.size == 1
        
        mean = values.sum / values.size.to_f
        variance = values.sum { |v| (v - mean) ** 2 } / values.size.to_f
        Math.sqrt(variance).round(2)
      end
      
      def find_scheduling_conflicts(stakeholder)
        conflicts = []
        tasks = stakeholder.tasks.where(status: ['in_progress', 'pending']).order(:start_date)
        
        tasks.each_with_index do |task, index|
          tasks[(index + 1)..-1].each do |other_task|
            if tasks_overlap?(task, other_task)
              conflicts << {
                tasks: [task, other_task],
                overlap_days: calculate_overlap_days(task, other_task),
                severity: assess_overlap_severity(task, other_task)
              }
            end
          end
        end
        
        conflicts
      end

      def calculate_overlap_days(task1, task2)
        overlap_start = [task1.start_date, task2.start_date].max
        overlap_end = [task1.end_date, task2.end_date].min
        (overlap_end - overlap_start + 1).to_i
      end

      def assess_overlap_severity(task1, task2)
        if task1.priority == 'critical' || task2.priority == 'critical'
          'high'
        elsif task1.priority == 'high' || task2.priority == 'high'
          'medium'
        else
          'low'
        end
      end

      def assess_conflict_impact(conflicts)
        high_severity = conflicts.count { |c| c[:severity] == 'high' }
        total_overlap_days = conflicts.sum { |c| c[:overlap_days] }
        
        {
          severity_distribution: conflicts.group_by { |c| c[:severity] }.transform_values(&:count),
          total_overlap_days: total_overlap_days,
          affected_tasks: conflicts.flat_map { |c| c[:tasks] }.uniq.count,
          risk_level: high_severity > 0 ? 'high' : 'medium'
        }
      end

      def generate_conflict_resolutions(conflicts)
        resolutions = []
        
        conflicts.each do |resource_conflict|
          resource_conflict[:conflicts].each do |conflict|
            resolutions << {
              stakeholder: resource_conflict[:stakeholder],
              conflict: conflict,
              options: [
                "Reschedule #{conflict[:tasks].first.name} to avoid overlap",
                "Assign #{conflict[:tasks].last.name} to another resource",
                "Negotiate extended timeline for both tasks",
                "Prioritize #{conflict[:tasks].max_by(&:priority).name} and delay the other"
              ]
            }
          end
        end
        
        resolutions
      end

      private

      def can_handle_task?(assignee, task)
        return false unless assignee

        # Check if assignee has required skills
        required_skills = task.required_skills || []
        return true if required_skills.empty?

        # For stakeholders, check certifications
        if assignee.is_a?(Immo::Promo::Stakeholder)
          stakeholder_skills = assignee.certifications.valid.pluck(:certification_type)
          return required_skills.all? { |skill| stakeholder_skills.include?(skill) }
        end

        # For users, assume they can handle basic tasks
        true
      end
    end
  end
end