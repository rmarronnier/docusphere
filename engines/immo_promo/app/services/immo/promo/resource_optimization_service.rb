module Immo
  module Promo
    class ResourceOptimizationService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def optimize_assignments
        {
          reassignments: generate_reassignments,
          new_assignments: assign_unassigned_tasks,
          load_balancing: balance_workload,
          efficiency_improvements: identify_efficiency_improvements
        }
      end

      def generate_reassignments
        reassignments = []
        
        overloaded_stakeholders = identify_overloaded_stakeholders
        underutilized_stakeholders = identify_underutilized_stakeholders
        
        overloaded_stakeholders.each do |stakeholder|
          transferable_tasks = find_transferable_tasks(stakeholder)
          
          transferable_tasks.each do |task|
            best_recipient = find_best_recipient(task, underutilized_stakeholders)
            
            if best_recipient
              reassignments << {
                task: task,
                from: stakeholder,
                to: best_recipient,
                reason: 'Load balancing',
                impact: calculate_reassignment_impact(task, stakeholder, best_recipient),
                priority: task.priority
              }
            end
          end
        end
        
        reassignments
      end

      def assign_unassigned_tasks
        assignments = []
        unassigned_tasks = project.tasks.where(stakeholder_id: nil).where.not(status: 'completed')
        
        unassigned_tasks.each do |task|
          best_assignee = find_best_assignee_for_task(task)
          
          if best_assignee
            assignments << {
              task: task,
              assignee: best_assignee,
              confidence: calculate_assignment_confidence(task, best_assignee),
              reason: generate_assignment_reason(task, best_assignee)
            }
          else
            assignments << {
              task: task,
              assignee: nil,
              reason: 'No suitable resource available',
              alternatives: suggest_alternatives(task)
            }
          end
        end
        
        assignments
      end

      def balance_workload
        imbalances = identify_workload_imbalances
        
        {
          current_balance: calculate_workload_balance,
          imbalances: imbalances,
          recommendations: generate_balancing_recommendations(imbalances)
        }
      end

      def identify_efficiency_improvements
        improvements = []
        
        # Skill mismatches
        skill_mismatches = find_skill_mismatches
        improvements.concat(skill_mismatches.map { |m| efficiency_improvement_from_mismatch(m) })
        
        # Task grouping opportunities
        grouping_opportunities = find_task_grouping_opportunities
        improvements.concat(grouping_opportunities.map { |g| efficiency_improvement_from_grouping(g) })
        
        # Resource underutilization
        underutilized = identify_underutilized_stakeholders
        improvements.concat(underutilized.map { |s| efficiency_improvement_from_underutilization(s) })
        
        improvements
      end

      def find_best_assignee_for_task(task)
        candidates = project.stakeholders.active
        
        scores = candidates.map do |stakeholder|
          {
            stakeholder: stakeholder,
            score: calculate_assignment_score(task, stakeholder)
          }
        end
        
        best = scores.max_by { |s| s[:score] }
        best && best[:score] > 0 ? best[:stakeholder] : nil
      end

      private

      def identify_overloaded_stakeholders
        project.stakeholders.active.select do |s|
          calculate_utilization(s) > 100
        end
      end

      def identify_underutilized_stakeholders
        project.stakeholders.active.select do |s|
          utilization = calculate_utilization(s)
          utilization < 70 && utilization > 0
        end
      end

      def calculate_utilization(stakeholder)
        allocated_hours = stakeholder.tasks
                                    .where(status: ['in_progress', 'pending'])
                                    .sum(:estimated_hours)
        
        available_hours = 40 # per week
        weeks_remaining = calculate_weeks_remaining
        
        return 0 if weeks_remaining == 0
        
        weekly_allocated = allocated_hours.to_f / weeks_remaining
        (weekly_allocated / available_hours * 100).round(2)
      end

      def calculate_weeks_remaining
        return 1 unless project.end_date
        weeks = ((project.end_date - Date.current) / 7.0).ceil
        [weeks, 1].max
      end

      def find_transferable_tasks(stakeholder)
        stakeholder.tasks
                   .where(status: 'pending')
                   .where('start_date > ?', 1.week.from_now)
                   .order(priority: :asc)
      end

      def find_best_recipient(task, candidates)
        return nil if candidates.empty?
        
        suitable_candidates = candidates.select do |candidate|
          has_required_skills?(candidate, task.required_skills || []) &&
          !has_scheduling_conflict?(candidate, task)
        end
        
        suitable_candidates.min_by { |c| calculate_utilization(c) }
      end

      def has_required_skills?(stakeholder, required_skills)
        return true if required_skills.empty?
        
        stakeholder_skills = stakeholder.certifications.pluck(:certification_type)
        (required_skills - stakeholder_skills).empty?
      end

      def has_scheduling_conflict?(stakeholder, task)
        return false unless task.start_date && task.end_date
        
        stakeholder.tasks.where(
          'start_date <= ? AND end_date >= ?',
          task.end_date,
          task.start_date
        ).exists?
      end

      def calculate_reassignment_impact(task, from, to)
        {
          from_utilization_change: calculate_utilization(from) - calculate_utilization_after_removal(from, task),
          to_utilization_change: calculate_utilization_after_addition(to, task) - calculate_utilization(to),
          schedule_impact: 'None if reassigned before start',
          skill_match: calculate_skill_match(to, task)
        }
      end

      def calculate_utilization_after_removal(stakeholder, task)
        current_hours = stakeholder.tasks
                                  .where(status: ['in_progress', 'pending'])
                                  .sum(:estimated_hours)
        
        new_hours = current_hours - task.estimated_hours
        available_hours = 40 * calculate_weeks_remaining
        
        return 0 if available_hours == 0
        (new_hours.to_f / available_hours * 100).round(2)
      end

      def calculate_utilization_after_addition(stakeholder, task)
        current_hours = stakeholder.tasks
                                  .where(status: ['in_progress', 'pending'])
                                  .sum(:estimated_hours)
        
        new_hours = current_hours + task.estimated_hours
        available_hours = 40 * calculate_weeks_remaining
        
        return 0 if available_hours == 0
        (new_hours.to_f / available_hours * 100).round(2)
      end

      def calculate_assignment_score(task, stakeholder)
        score = 0
        
        # Skill match
        score += calculate_skill_match(stakeholder, task) * 40
        
        # Availability
        utilization = calculate_utilization(stakeholder)
        if utilization < 80
          score += (80 - utilization)
        end
        
        # Past performance
        score += calculate_performance_score(stakeholder) * 20
        
        # Schedule compatibility
        score += 10 unless has_scheduling_conflict?(stakeholder, task)
        
        score
      end

      def calculate_skill_match(stakeholder, task)
        return 1.0 if task.required_skills.blank?
        
        stakeholder_skills = stakeholder.certifications.pluck(:certification_type)
        matched_skills = (task.required_skills & stakeholder_skills).count
        required_count = task.required_skills.count
        
        return 0 if required_count == 0
        matched_skills.to_f / required_count
      end

      def calculate_performance_score(stakeholder)
        case stakeholder.performance_rating
        when 'excellent' then 1.0
        when 'good' then 0.8
        when 'average' then 0.6
        when 'below_average' then 0.4
        else 0.5
        end
      end

      def calculate_assignment_confidence(task, assignee)
        skill_match = calculate_skill_match(assignee, task)
        availability = 1.0 - (calculate_utilization(assignee) / 100.0)
        performance = calculate_performance_score(assignee)
        
        ((skill_match + availability + performance) / 3 * 100).round
      end

      def generate_assignment_reason(task, assignee)
        reasons = []
        
        skill_match = calculate_skill_match(assignee, task)
        reasons << "High skill match (#{(skill_match * 100).round}%)" if skill_match > 0.8
        
        utilization = calculate_utilization(assignee)
        reasons << "Good availability (#{(100 - utilization).round}% free)" if utilization < 70
        
        performance = calculate_performance_score(assignee)
        reasons << "Strong performance record" if performance > 0.8
        
        reasons.join(", ")
      end

      def suggest_alternatives(task)
        [
          'Consider hiring specialized contractor',
          'Break task into smaller subtasks',
          'Delay task until resources available',
          'Outsource to external provider'
        ]
      end

      def identify_workload_imbalances
        stakeholder_utilizations = project.stakeholders.active.map do |s|
          {
            stakeholder: s,
            utilization: calculate_utilization(s)
          }
        end
        
        avg_utilization = stakeholder_utilizations.sum { |s| s[:utilization] } / stakeholder_utilizations.size.to_f
        
        stakeholder_utilizations.select do |s|
          (s[:utilization] - avg_utilization).abs > 20
        end
      end

      def calculate_workload_balance
        utilizations = project.stakeholders.active.map { |s| calculate_utilization(s) }
        
        {
          average: utilizations.sum / utilizations.size.to_f,
          standard_deviation: calculate_standard_deviation(utilizations),
          min: utilizations.min,
          max: utilizations.max,
          range: utilizations.max - utilizations.min
        }
      end

      def calculate_standard_deviation(values)
        return 0 if values.empty?
        
        mean = values.sum / values.size.to_f
        variance = values.sum { |v| (v - mean) ** 2 } / values.size.to_f
        Math.sqrt(variance)
      end

      def generate_balancing_recommendations(imbalances)
        recommendations = []
        
        overloaded = imbalances.select { |i| i[:utilization] > 100 }
        underutilized = imbalances.select { |i| i[:utilization] < 50 }
        
        if overloaded.any? && underutilized.any?
          recommendations << {
            type: 'redistribution',
            priority: 'high',
            action: 'Redistribute tasks from overloaded to underutilized resources',
            from: overloaded.map { |i| i[:stakeholder] },
            to: underutilized.map { |i| i[:stakeholder] }
          }
        end
        
        if overloaded.any? && underutilized.empty?
          recommendations << {
            type: 'capacity_increase',
            priority: 'high',
            action: 'Add more resources or extend timeline',
            affected: overloaded.map { |i| i[:stakeholder] }
          }
        end
        
        recommendations
      end

      def find_skill_mismatches
        mismatches = []
        
        project.tasks.includes(:stakeholder).where.not(stakeholder_id: nil).each do |task|
          next if task.required_skills.blank?
          
          skill_match = calculate_skill_match(task.stakeholder, task)
          if skill_match < 1.0
            mismatches << {
              task: task,
              stakeholder: task.stakeholder,
              match_percentage: skill_match * 100,
              missing_skills: task.required_skills - task.stakeholder.certifications.pluck(:certification_type)
            }
          end
        end
        
        mismatches
      end

      def find_task_grouping_opportunities
        opportunities = []
        
        # Group by stakeholder and phase
        task_groups = project.tasks
                            .where(status: 'pending')
                            .includes(:stakeholder, :phase)
                            .group_by { |t| [t.stakeholder_id, t.phase_id] }
        
        task_groups.each do |(stakeholder_id, phase_id), tasks|
          next if tasks.size < 2
          
          if can_group_tasks?(tasks)
            opportunities << {
              stakeholder_id: stakeholder_id,
              phase_id: phase_id,
              tasks: tasks,
              potential_savings: estimate_grouping_savings(tasks)
            }
          end
        end
        
        opportunities
      end

      def can_group_tasks?(tasks)
        # Check if tasks have overlapping or close dates
        sorted_tasks = tasks.sort_by(&:start_date)
        
        sorted_tasks.each_cons(2).any? do |task1, task2|
          next false unless task1.end_date && task2.start_date
          (task2.start_date - task1.end_date).days <= 3
        end
      end

      def estimate_grouping_savings(tasks)
        # Estimate 10% efficiency gain per grouped task
        total_hours = tasks.sum(&:estimated_hours)
        (total_hours * 0.1).round
      end

      def efficiency_improvement_from_mismatch(mismatch)
        {
          type: 'skill_mismatch',
          priority: mismatch[:match_percentage] < 50 ? 'high' : 'medium',
          task: mismatch[:task],
          current_assignee: mismatch[:stakeholder],
          issue: "Only #{mismatch[:match_percentage].round}% skill match",
          recommendation: 'Reassign to qualified resource or provide training',
          missing_skills: mismatch[:missing_skills]
        }
      end

      def efficiency_improvement_from_grouping(grouping)
        {
          type: 'task_grouping',
          priority: 'medium',
          tasks: grouping[:tasks],
          stakeholder_id: grouping[:stakeholder_id],
          phase_id: grouping[:phase_id],
          recommendation: 'Group these tasks to reduce overhead',
          potential_time_savings: "#{grouping[:potential_savings]} hours"
        }
      end

      def efficiency_improvement_from_underutilization(stakeholder)
        utilization = calculate_utilization(stakeholder)
        
        {
          type: 'underutilization',
          priority: utilization < 30 ? 'high' : 'medium',
          stakeholder: stakeholder,
          current_utilization: "#{utilization}%",
          recommendation: 'Assign more tasks or consider reallocation',
          available_capacity: "#{(100 - utilization).round}%"
        }
      end
    end
  end
end