module Immo
  module Promo
    class ProjectResourceService
      attr_reader :project

      def initialize(project)
        @project = project
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
        optimization_plan = {
          reassignments: [],
          new_assignments: [],
          load_balancing: []
        }
        
        # Identify overloaded and underutilized resources
        overloaded = project.overloaded_stakeholders
        available = project.available_stakeholders
        
        # Generate reassignment recommendations
        overloaded.each do |stakeholder|
          tasks_to_reassign = identify_tasks_to_reassign(stakeholder)
          available_assignees = find_suitable_assignees(tasks_to_reassign, available)
          
          tasks_to_reassign.zip(available_assignees).each do |task, new_assignee|
            next unless new_assignee
            
            optimization_plan[:reassignments] << {
              task: task,
              from: stakeholder,
              to: new_assignee,
              reason: 'Resource overload',
              impact: calculate_reassignment_impact(task, stakeholder, new_assignee)
            }
          end
        end
        
        # Identify unassigned critical tasks
        unassigned_tasks = find_unassigned_critical_tasks
        unassigned_tasks.each do |task|
          suitable_assignee = find_best_assignee_for_task(task, available)
          if suitable_assignee
            optimization_plan[:new_assignments] << {
              task: task,
              assignee: suitable_assignee,
              reason: 'Critical task requires assignment',
              priority: task.priority
            }
          end
        end
        
        optimization_plan
      end

      def resource_capacity_planning
        {
          current_capacity: calculate_current_capacity,
          required_capacity: calculate_required_capacity,
          capacity_gap: calculate_capacity_gap,
          peak_periods: identify_peak_resource_periods,
          recommendations: capacity_recommendations
        }
      end

      def skill_matrix_analysis
        skills = {}
        
        project.stakeholders.each do |stakeholder|
          stakeholder.skills.each do |skill|
            skills[skill] ||= []
            skills[skill] << stakeholder
          end
        end
        
        {
          available_skills: skills.keys,
          skill_distribution: skills.transform_values(&:count),
          skill_gaps: identify_skill_gaps,
          critical_skill_dependencies: identify_critical_skill_dependencies
        }
      end

      def resource_conflict_calendar
        conflicts = []
        
        # Check for scheduling conflicts
        project.stakeholders.each do |stakeholder|
          overlapping_tasks = find_overlapping_tasks(stakeholder)
          if overlapping_tasks.any?
            conflicts << {
              stakeholder: stakeholder.name,
              type: 'scheduling_conflict',
              tasks: overlapping_tasks,
              dates: extract_conflict_dates(overlapping_tasks)
            }
          end
        end
        
        # Check for capacity conflicts
        capacity_conflicts = identify_capacity_conflicts
        conflicts.concat(capacity_conflicts)
        
        conflicts.sort_by { |c| c[:dates]&.first || Date.current }
      end

      private

      def stakeholder_summary(stakeholder)
        {
          id: stakeholder.id,
          name: stakeholder.name,
          role: stakeholder.role,
          company: stakeholder.company_name,
          availability: stakeholder.availability_percentage || 100,
          skills: stakeholder.skills || []
        }
      end

      def calculate_stakeholder_workload(resource)
        # Get tasks based on resource type
        active_tasks = if resource.is_a?(User)
                        Immo::Promo::Task.where(assigned_to: resource, status: ['pending', 'in_progress'])
                      else
                        resource.tasks.where(status: ['pending', 'in_progress'])
                      end
        
        {
          total_hours: active_tasks.sum(:estimated_hours),
          task_count: active_tasks.count,
          by_priority: active_tasks.group(:priority).count,
          by_phase: active_tasks.joins(:phase).group('immo_promo_phases.name').count,
          utilization_percentage: calculate_utilization_percentage(resource)
        }
      end

      def task_load_details(tasks)
        tasks.where(status: ['pending', 'in_progress']).map do |task|
          {
            id: task.id,
            name: task.name,
            phase: task.phase.name,
            priority: task.priority,
            estimated_hours: task.estimated_hours,
            start_date: task.start_date,
            end_date: task.end_date,
            status: task.status
          }
        end
      end

      def calculate_availability(resource)
        base_hours = 40.0 # Standard work week
        
        # Handle both User and Stakeholder
        availability_factor = if resource.respond_to?(:availability_percentage)
                               (resource.availability_percentage || 100) / 100.0
                             else
                               1.0 # Assume 100% for users
                             end
        
        available_hours = base_hours * availability_factor
        
        # Get tasks based on resource type
        tasks_relation = if resource.is_a?(User)
                          Immo::Promo::Task.where(assigned_to: resource)
                        else
                          resource.tasks
                        end
        
        committed_hours = tasks_relation
                         .where(status: ['pending', 'in_progress'])
                         .sum(:estimated_hours)
        
        {
          total_available_hours: available_hours,
          committed_hours: committed_hours,
          remaining_hours: available_hours - committed_hours,
          is_available: committed_hours < available_hours
        }
      end

      def calculate_efficiency_metrics(stakeholder)
        completed_tasks = stakeholder.tasks.where(status: 'completed')
        
        return default_efficiency_metrics if completed_tasks.empty?
        
        on_time_completions = completed_tasks.select do |task|
          task.actual_end_date && task.end_date && task.actual_end_date <= task.end_date
        end.count
        
        actual_vs_estimated = completed_tasks.map do |task|
          next unless task.actual_hours && task.estimated_hours && task.estimated_hours > 0
          task.actual_hours.to_f / task.estimated_hours
        end.compact
        
        {
          completion_rate: (completed_tasks.count.to_f / stakeholder.tasks.count * 100).round(2),
          on_time_delivery_rate: (on_time_completions.to_f / completed_tasks.count * 100).round(2),
          average_efficiency: actual_vs_estimated.empty? ? 100 : (actual_vs_estimated.sum / actual_vs_estimated.count * 100).round(2),
          tasks_completed: completed_tasks.count
        }
      end

      def default_efficiency_metrics
        {
          completion_rate: 0,
          on_time_delivery_rate: 0,
          average_efficiency: 100,
          tasks_completed: 0
        }
      end

      def stakeholder_allocation_summary
        project.stakeholders.map do |stakeholder|
          workload = calculate_stakeholder_workload(stakeholder)
          availability = calculate_availability(stakeholder)
          
          {
            name: stakeholder.name,
            role: stakeholder.role,
            utilization: workload[:utilization_percentage],
            status: resource_status(workload[:utilization_percentage]),
            available_hours: availability[:remaining_hours]
          }
        end
      end

      def resource_status(utilization)
        if utilization > 100
          'overloaded'
        elsif utilization > 80
          'fully_utilized'
        elsif utilization > 50
          'well_utilized'
        elsif utilization > 20
          'underutilized'
        else
          'idle'
        end
      end

      def resource_allocation_by_phase
        project.phases.includes(:tasks).map do |phase|
          tasks = phase.tasks.includes(:assigned_to)
          assigned_resources = tasks.map(&:assigned_to).compact.uniq
          
          {
            phase: phase.name,
            status: phase.status,
            resource_count: assigned_resources.count,
            total_hours: tasks.sum(:estimated_hours),
            resources: assigned_resources.map(&:full_name),
            workload_distribution: calculate_phase_workload_distribution(tasks)
          }
        end
      end

      def calculate_phase_workload_distribution(tasks)
        distribution = {}
        
        tasks.group_by(&:assigned_to).each do |assignee, assignee_tasks|
          next unless assignee
          
          distribution[assignee.full_name] = {
            task_count: assignee_tasks.count,
            total_hours: assignee_tasks.sum(:estimated_hours),
            percentage: (assignee_tasks.sum(:estimated_hours).to_f / tasks.sum(:estimated_hours) * 100).round(2)
          }
        end
        
        distribution
      end

      def calculate_utilization_metrics
        total_capacity = project.stakeholders.sum do |s|
          40.0 * (s.availability_percentage || 100) / 100.0
        end
        
        total_allocated = project.stakeholders.sum do |s|
          s.tasks.where(status: ['pending', 'in_progress']).sum(:estimated_hours)
        end
        
        {
          total_capacity_hours: total_capacity,
          total_allocated_hours: total_allocated,
          overall_utilization: total_capacity.zero? ? 0 : (total_allocated / total_capacity * 100).round(2),
          resource_efficiency: calculate_resource_efficiency
        }
      end

      def calculate_resource_efficiency
        completed_tasks = Immo::Promo::Task.joins(:phase)
                                           .where(phase: project.phases, status: 'completed')
                                           .where.not(actual_hours: nil, estimated_hours: nil)
        
        return 100 if completed_tasks.empty?
        
        total_estimated = completed_tasks.sum(:estimated_hours)
        total_actual = completed_tasks.sum(:actual_hours)
        
        return 100 if total_actual.zero?
        
        (total_estimated.to_f / total_actual * 100).round(2)
      end

      def identify_resource_conflicts
        conflicts = []
        
        # Overallocation conflicts
        project.overloaded_stakeholders.each do |stakeholder|
          conflicts << {
            type: 'overallocation',
            resource: stakeholder.name,
            severity: 'high',
            allocated_hours: calculate_allocated_hours(stakeholder),
            capacity_hours: 40.0 * (stakeholder.availability_percentage || 100) / 100.0,
            affected_tasks: stakeholder.tasks.where(status: ['pending', 'in_progress']).count
          }
        end
        
        # Skill mismatch conflicts
        skill_conflicts = identify_skill_mismatches
        conflicts.concat(skill_conflicts)
        
        # Availability conflicts
        availability_conflicts = identify_availability_conflicts
        conflicts.concat(availability_conflicts)
        
        conflicts
      end

      def calculate_allocated_hours(stakeholder)
        stakeholder.tasks.where(status: ['pending', 'in_progress']).sum(:estimated_hours)
      end

      def identify_skill_mismatches
        mismatches = []
        
        # Check tasks requiring specific skills
        tasks_with_requirements = Immo::Promo::Task.joins(:phase)
                                                   .where(phase: project.phases)
                                                   .where.not(required_skills: nil)
        
        tasks_with_requirements.each do |task|
          if task.assigned_to && !has_required_skills?(task.assigned_to, task.required_skills)
            mismatches << {
              type: 'skill_mismatch',
              resource: task.assigned_to.full_name,
              task: task.name,
              required_skills: task.required_skills,
              severity: 'medium'
            }
          end
        end
        
        mismatches
      end

      def has_required_skills?(stakeholder, required_skills)
        return true if required_skills.blank?
        
        stakeholder_skills = stakeholder.skills || []
        (required_skills - stakeholder_skills).empty?
      end

      def identify_availability_conflicts
        conflicts = []
        
        project.stakeholders.each do |stakeholder|
          # Check if stakeholder has tasks scheduled outside their availability
          unavailable_periods = stakeholder.unavailable_periods || []
          
          unavailable_periods.each do |period|
            conflicting_tasks = stakeholder.tasks
                                          .where('start_date <= ? AND end_date >= ?', period[:end_date], period[:start_date])
                                          .where(status: ['pending', 'in_progress'])
            
            if conflicting_tasks.any?
              conflicts << {
                type: 'availability_conflict',
                resource: stakeholder.name,
                period: period,
                affected_tasks: conflicting_tasks.map(&:name),
                severity: 'high'
              }
            end
          end
        end
        
        conflicts
      end

      def optimization_recommendations
        recommendations = []
        
        # Load balancing recommendations
        if needs_load_balancing?
          recommendations << {
            type: 'load_balancing',
            priority: 'high',
            description: 'Significant workload imbalance detected',
            action: 'Redistribute tasks from overloaded to underutilized resources'
          }
        end
        
        # Skill optimization recommendations
        skill_gaps = identify_skill_gaps
        if skill_gaps.any?
          recommendations << {
            type: 'skill_development',
            priority: 'medium',
            description: 'Critical skill gaps identified',
            skills_needed: skill_gaps,
            action: 'Consider training or hiring for missing skills'
          }
        end
        
        # Capacity recommendations
        if capacity_shortage?
          recommendations << {
            type: 'capacity_increase',
            priority: 'high',
            description: 'Insufficient resource capacity for project demands',
            shortage_hours: calculate_capacity_gap[:shortage_hours],
            action: 'Add resources or extend timeline'
          }
        end
        
        recommendations
      end

      def needs_load_balancing?
        utilizations = project.stakeholders.map do |s|
          calculate_utilization_percentage(s)
        end
        
        return false if utilizations.empty?
        
        # Check if variance is high
        avg = utilizations.sum / utilizations.count
        variance = utilizations.map { |u| (u - avg) ** 2 }.sum / utilizations.count
        std_dev = Math.sqrt(variance)
        
        std_dev > 30 # High standard deviation indicates imbalance
      end

      def calculate_utilization_percentage(stakeholder)
        capacity = 40.0 * (stakeholder.availability_percentage || 100) / 100.0
        return 0 if capacity.zero?
        
        allocated = stakeholder.tasks.where(status: ['pending', 'in_progress']).sum(:estimated_hours)
        (allocated / capacity * 100).round(2)
      end

      def identify_tasks_to_reassign(stakeholder)
        # Prioritize low-priority, non-critical tasks for reassignment
        stakeholder.tasks
                   .where(status: ['pending', 'in_progress'])
                   .where.not(priority: 'critical')
                   .order(priority: :desc, estimated_hours: :desc)
                   .limit(3)
      end

      def find_suitable_assignees(tasks, available_stakeholders)
        tasks.map do |task|
          available_stakeholders.min_by do |stakeholder|
            next Float::INFINITY unless can_handle_task?(stakeholder, task)
            
            calculate_stakeholder_workload(stakeholder)[:total_hours]
          end
        end
      end

      def can_handle_task?(stakeholder, task)
        # Check skills match
        return false if task.required_skills.present? && !has_required_skills?(stakeholder, task.required_skills)
        
        # Check capacity
        availability = calculate_availability(stakeholder)
        availability[:remaining_hours] >= (task.estimated_hours || 0)
      end
      
      def has_required_skills?(resource, required_skills)
        return true if required_skills.blank?
        
        # For now, assume all users/stakeholders have all skills
        # This can be enhanced later with actual skill checking
        true
      end

      def calculate_reassignment_impact(task, from_stakeholder, to_stakeholder)
        {
          workload_reduction_from: task.estimated_hours,
          workload_increase_to: task.estimated_hours,
          from_utilization_after: calculate_utilization_after_removal(from_stakeholder, task),
          to_utilization_after: calculate_utilization_after_addition(to_stakeholder, task)
        }
      end

      def calculate_utilization_after_removal(stakeholder, task)
        current_hours = calculate_allocated_hours(stakeholder)
        new_hours = current_hours - task.estimated_hours
        capacity = 40.0 * (stakeholder.availability_percentage || 100) / 100.0
        
        (new_hours / capacity * 100).round(2)
      end

      def calculate_utilization_after_addition(stakeholder, task)
        current_hours = calculate_allocated_hours(stakeholder)
        new_hours = current_hours + task.estimated_hours
        capacity = 40.0 * (stakeholder.availability_percentage || 100) / 100.0
        
        (new_hours / capacity * 100).round(2)
      end

      def find_unassigned_critical_tasks
        Immo::Promo::Task.joins(:phase)
                         .where(phase: project.phases)
                         .where(assigned_to_id: nil)
                         .where(priority: ['critical', 'high'])
                         .order(priority: :asc)
      end

      def find_best_assignee_for_task(task, available_stakeholders)
        suitable_stakeholders = available_stakeholders.select do |s|
          can_handle_task?(s, task)
        end
        
        return nil if suitable_stakeholders.empty?
        
        # Prefer stakeholder with matching skills and lowest workload
        suitable_stakeholders.min_by do |s|
          skill_match_score = calculate_skill_match_score(s, task)
          workload_score = calculate_stakeholder_workload(s)[:total_hours]
          
          # Weighted score (lower is better)
          workload_score - (skill_match_score * 10)
        end
      end

      def calculate_skill_match_score(stakeholder, task)
        return 0 if task.required_skills.blank?
        
        stakeholder_skills = stakeholder.skills || []
        matched_skills = (task.required_skills & stakeholder_skills).count
        total_required = task.required_skills.count
        
        total_required.zero? ? 0 : (matched_skills.to_f / total_required)
      end

      def calculate_current_capacity
        weekly_capacity = project.stakeholders.sum do |s|
          40.0 * (s.availability_percentage || 100) / 100.0
        end
        
        {
          weekly_hours: weekly_capacity,
          monthly_hours: weekly_capacity * 4.33,
          resource_count: project.stakeholders.count,
          by_role: capacity_by_role
        }
      end

      def capacity_by_role
        project.stakeholders.group_by(&:role).transform_values do |stakeholders|
          stakeholders.sum { |s| 40.0 * (s.availability_percentage || 100) / 100.0 }
        end
      end

      def calculate_required_capacity
        remaining_tasks = Immo::Promo::Task.joins(:phase)
                                           .where(phase: project.phases)
                                           .where.not(status: 'completed')
        
        total_hours = remaining_tasks.sum(:estimated_hours)
        weeks_remaining = calculate_weeks_remaining
        
        {
          total_hours_needed: total_hours,
          weekly_hours_needed: weeks_remaining.zero? ? 0 : (total_hours / weeks_remaining).round(2),
          by_phase: required_capacity_by_phase,
          by_priority: remaining_tasks.group(:priority).sum(:estimated_hours)
        }
      end

      def calculate_weeks_remaining
        return 0 unless project.end_date
        
        weeks = ((project.end_date - Date.current) / 7.0).round(1)
        [weeks, 0].max
      end

      def required_capacity_by_phase
        project.phases.includes(:tasks).map do |phase|
          remaining_hours = phase.tasks.where.not(status: 'completed').sum(:estimated_hours)
          {
            phase: phase.name,
            hours_needed: remaining_hours,
            status: phase.status
          }
        end
      end

      def calculate_capacity_gap
        current = calculate_current_capacity
        required = calculate_required_capacity
        
        weekly_gap = required[:weekly_hours_needed] - current[:weekly_hours]
        
        {
          has_shortage: weekly_gap > 0,
          shortage_hours: [weekly_gap, 0].max,
          shortage_percentage: current[:weekly_hours].zero? ? 0 : (weekly_gap / current[:weekly_hours] * 100).round(2),
          resources_needed: weekly_gap > 0 ? (weekly_gap / 40.0).ceil : 0
        }
      end

      def capacity_shortage?
        calculate_capacity_gap[:has_shortage]
      end

      def identify_peak_resource_periods
        # Group tasks by week
        weekly_demand = Hash.new(0)
        
        Immo::Promo::Task.joins(:phase)
                         .where(phase: project.phases)
                         .where.not(start_date: nil, end_date: nil)
                         .each do |task|
          weeks = weeks_between(task.start_date, task.end_date)
          hours_per_week = task.estimated_hours.to_f / weeks.count
          
          weeks.each do |week|
            weekly_demand[week] += hours_per_week
          end
        end
        
        # Identify peaks (weeks with demand > capacity)
        capacity = calculate_current_capacity[:weekly_hours]
        peaks = weekly_demand.select { |_week, demand| demand > capacity }
        
        peaks.map do |week, demand|
          {
            week_start: week,
            demand_hours: demand.round(2),
            capacity_hours: capacity,
            overload_percentage: ((demand - capacity) / capacity * 100).round(2)
          }
        end.sort_by { |p| p[:week_start] }
      end

      def weeks_between(start_date, end_date)
        weeks = []
        current_week = start_date.beginning_of_week
        
        while current_week <= end_date
          weeks << current_week
          current_week += 1.week
        end
        
        weeks
      end

      def capacity_recommendations
        recommendations = []
        gap = calculate_capacity_gap
        
        if gap[:has_shortage]
          recommendations << "Add #{gap[:resources_needed]} resources to meet project timeline"
          recommendations << "Focus on hiring for roles with highest demand: #{top_demand_roles.join(', ')}"
        end
        
        peaks = identify_peak_resource_periods
        if peaks.any?
          recommendations << "Plan for resource surge during peak periods: #{peaks.first(3).map { |p| p[:week_start].strftime('%B %Y') }.join(', ')}"
        end
        
        if needs_load_balancing?
          recommendations << "Implement resource leveling to smooth workload distribution"
        end
        
        recommendations
      end

      def top_demand_roles
        required_by_role = Hash.new(0)
        
        Immo::Promo::Task.joins(:phase)
                         .where(phase: project.phases)
                         .where.not(status: 'completed')
                         .includes(:assigned_to)
                         .each do |task|
          role = task.assigned_to&.role || 'unassigned'
          required_by_role[role] += task.estimated_hours
        end
        
        required_by_role.sort_by { |_role, hours| -hours }
                       .first(3)
                       .map(&:first)
      end

      def identify_skill_gaps
        required_skills = Set.new
        available_skills = Set.new
        
        # Collect required skills from tasks
        Immo::Promo::Task.joins(:phase)
                         .where(phase: project.phases)
                         .where.not(required_skills: nil)
                         .each do |task|
          required_skills.merge(task.required_skills)
        end
        
        # Collect available skills from stakeholders
        project.stakeholders.each do |stakeholder|
          available_skills.merge(stakeholder.skills || [])
        end
        
        (required_skills - available_skills).to_a
      end

      def identify_critical_skill_dependencies
        critical_skills = {}
        
        Immo::Promo::Task.joins(:phase)
                         .where(phase: project.phases)
                         .where(priority: 'critical')
                         .where.not(required_skills: nil)
                         .each do |task|
          task.required_skills.each do |skill|
            critical_skills[skill] ||= []
            critical_skills[skill] << task
          end
        end
        
        critical_skills.transform_values(&:count)
      end

      def find_overlapping_tasks(stakeholder)
        tasks = stakeholder.tasks
                          .where(status: ['pending', 'in_progress'])
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
        task1.start_date <= task2.end_date && task2.start_date <= task1.end_date
      end

      def extract_conflict_dates(overlapping_tasks)
        all_dates = overlapping_tasks.flatten.map { |task| [task.start_date, task.end_date] }.flatten.compact
        return [] if all_dates.empty?
        
        [all_dates.min, all_dates.max]
      end

      def identify_capacity_conflicts
        conflicts = []
        
        peak_periods = identify_peak_resource_periods
        peak_periods.each do |period|
          if period[:overload_percentage] > 20
            conflicts << {
              type: 'capacity_exceeded',
              week: period[:week_start],
              severity: period[:overload_percentage] > 50 ? 'critical' : 'high',
              overload_hours: period[:demand_hours] - period[:capacity_hours],
              dates: [period[:week_start], period[:week_start] + 6.days]
            }
          end
        end
        
        conflicts
      end
      
      def calculate_utilization_percentage(resource)
        availability = calculate_availability(resource)
        total_available = availability[:total_available_hours]
        return 0 if total_available.zero?
        
        (availability[:committed_hours] / total_available * 100).round(2)
      end
      
      def calculate_skill_match_score(stakeholder, task)
        return 1.0 if task.required_skills.blank?
        
        # Simple matching for now
        # Can be enhanced with actual skill comparison
        0.8
      end
    end
  end
end