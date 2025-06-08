module Immo
  module Promo
    class ProjectScheduleService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def critical_path_analysis
        critical_phases = project.critical_phases.includes(:phase_dependencies, :tasks)
        
        critical_phases.map do |phase|
          {
            phase: phase_summary(phase),
            slack_time: calculate_slack_time(phase),
            is_on_critical_path: is_on_critical_path?(phase),
            dependencies: phase_dependencies(phase),
            impact_score: calculate_impact_score(phase)
          }
        end
      end

      def schedule_alerts
        alerts = []
        
        alerts.concat(overdue_milestone_alerts)
        alerts.concat(upcoming_critical_milestone_alerts)
        alerts.concat(expiring_permit_alerts)
        alerts.concat(phase_delay_alerts)
        alerts.concat(resource_conflict_alerts)
        
        alerts.sort_by { |alert| alert_priority(alert[:type]) }
      end

      def timeline_optimization_suggestions
        suggestions = []
        
        # Check for phases that can be parallelized
        suggestions.concat(parallelization_opportunities)
        
        # Check for resource bottlenecks
        suggestions.concat(resource_optimization_suggestions)
        
        # Check for buffer time opportunities
        suggestions.concat(buffer_time_suggestions)
        
        suggestions
      end

      def calculate_project_delays
        {
          overall_delay: calculate_overall_delay,
          phase_delays: calculate_phase_delays,
          milestone_delays: calculate_milestone_delays,
          cascading_impacts: calculate_cascading_impacts
        }
      end

      def reschedule_from_phase(phase, new_start_date)
        affected_phases = find_dependent_phases(phase)
        
        rescheduling_plan = {
          direct_update: {
            phase: phase,
            original_start: phase.start_date,
            new_start: new_start_date,
            shift_days: (new_start_date - phase.start_date).to_i
          },
          cascading_updates: []
        }
        
        # Calculate cascading effects
        affected_phases.each do |affected_phase|
          shift = calculate_required_shift(affected_phase, phase, new_start_date)
          if shift > 0
            rescheduling_plan[:cascading_updates] << {
              phase: affected_phase,
              original_start: affected_phase.start_date,
              new_start: affected_phase.start_date + shift.days,
              shift_days: shift
            }
          end
        end
        
        rescheduling_plan
      end

      def gantt_chart_data
        phases = project.phases.includes(:tasks, :milestones).order(:position)
        
        {
          project: {
            name: project.name,
            start_date: project.start_date,
            end_date: project.end_date
          },
          phases: phases.map do |phase|
            {
              id: phase.id,
              name: phase.name,
              start_date: phase.start_date,
              end_date: phase.end_date,
              progress: phase.completion_percentage,
              dependencies: phase.prerequisite_phases.pluck(:id),
              is_critical: phase.is_critical?,
              status: phase.status,
              tasks: phase.tasks.map do |task|
                {
                  id: task.id,
                  name: task.name,
                  start_date: task.start_date,
                  end_date: task.end_date,
                  assignee: task.assigned_to&.full_name,
                  status: task.status
                }
              end,
              milestones: phase.milestones.map do |milestone|
                {
                  id: milestone.id,
                  name: milestone.name,
                  date: milestone.target_date,
                  status: milestone.status
                }
              end
            }
          end
        }
      end

      private

      def phase_summary(phase)
        {
          id: phase.id,
          name: phase.name,
          type: phase.phase_type,
          status: phase.status,
          start_date: phase.start_date,
          end_date: phase.end_date,
          duration: phase_duration(phase),
          is_critical: phase.is_critical?
        }
      end

      def calculate_slack_time(phase)
        return Float::INFINITY unless phase.end_date
        
        latest_finish = calculate_latest_finish_time(phase)
        scheduled_finish = phase.end_date
        
        (latest_finish - scheduled_finish).to_i
      end

      def calculate_latest_finish_time(phase)
        dependent_phases = Immo::Promo::PhaseDependency
                          .where(prerequisite_phase: phase)
                          .includes(:dependent_phase)
                          .map(&:dependent_phase)
        
        if dependent_phases.empty?
          project.end_date || 1.year.from_now
        else
          dependent_phases.map(&:start_date).compact.min || project.end_date || 1.year.from_now
        end
      end

      def is_on_critical_path?(phase)
        calculate_slack_time(phase) <= 0
      end

      def phase_dependencies(phase)
        phase.phase_dependencies.includes(:dependent_phase).map do |dep|
          {
            dependent_phase: dep.dependent_phase.name,
            dependency_type: dep.dependency_type,
            lag_time: dep.lag_time
          }
        end
      end

      def calculate_impact_score(phase)
        score = 0
        
        # Base score from phase type
        score += phase_weight(phase)
        
        # Add points for dependencies
        score += phase.dependent_phases.count * 10
        
        # Add points for critical milestones
        score += phase.milestones.where(is_critical: true).count * 15
        
        # Add points for being on critical path
        score += 50 if is_on_critical_path?(phase)
        
        score
      end

      def phase_weight(phase)
        case phase.phase_type
        when 'construction' then 50
        when 'permits' then 30
        when 'studies' then 15
        when 'reception' then 3
        when 'delivery' then 2
        else 10
        end
      end

      def overdue_milestone_alerts
        project.overdue_milestones.map do |milestone|
          days_overdue = (Date.current - milestone.target_date).to_i
          {
            type: 'danger',
            category: 'milestone_overdue',
            title: 'Milestone Overdue',
            message: "#{milestone.name} is #{days_overdue} days overdue (due #{milestone.target_date.strftime('%d/%m/%Y')})",
            resource: milestone,
            days_overdue: days_overdue
          }
        end
      end

      def upcoming_critical_milestone_alerts
        project.critical_milestones
               .where(target_date: Date.current..7.days.from_now, status: 'pending')
               .map do |milestone|
          days_until = (milestone.target_date - Date.current).to_i
          {
            type: 'warning',
            category: 'milestone_upcoming',
            title: 'Critical Milestone Approaching',
            message: "#{milestone.name} due in #{days_until} days (#{milestone.target_date.strftime('%d/%m/%Y')})",
            resource: milestone,
            days_until: days_until
          }
        end
      end

      def expiring_permit_alerts
        project.expiring_permits.map do |permit|
          days_until = (permit.expiry_date - Date.current).to_i
          {
            type: 'warning',
            category: 'permit_expiring',
            title: 'Permit Expiring Soon',
            message: "#{permit.permit_type.humanize} expires in #{days_until} days (#{permit.expiry_date.strftime('%d/%m/%Y')})",
            resource: permit,
            days_until: days_until
          }
        end
      end

      def phase_delay_alerts
        project.phases.select(&:is_delayed?).map do |phase|
          delay_days = calculate_phase_delay(phase)
          {
            type: 'danger',
            category: 'phase_delayed',
            title: 'Phase Delayed',
            message: "#{phase.name} is #{delay_days} days behind schedule",
            resource: phase,
            delay_days: delay_days
          }
        end
      end

      def resource_conflict_alerts
        conflicts = []
        
        # Check for overallocated resources
        project.overloaded_stakeholders.each do |stakeholder|
          conflicts << {
            type: 'warning',
            category: 'resource_overload',
            title: 'Resource Overallocated',
            message: "#{stakeholder.name} is overallocated with more than 40 hours/week",
            resource: stakeholder
          }
        end
        
        conflicts
      end

      def alert_priority(type)
        case type
        when 'danger' then 1
        when 'warning' then 2
        when 'info' then 3
        else 4
        end
      end

      def parallelization_opportunities
        suggestions = []
        
        project.phases.each do |phase|
          # Find phases that could potentially run in parallel
          potential_parallel = project.phases
                                     .where.not(id: phase.id)
                                     .where.not(id: phase.prerequisite_phases.pluck(:id))
                                     .where.not(id: phase.dependent_phases.pluck(:id))
          
          if potential_parallel.any? && phase.start_date && potential_parallel.any? { |p| p.start_date && phases_overlap?(phase, p) }
            suggestions << {
              type: 'parallelization',
              phase: phase.name,
              potential_parallel: potential_parallel.pluck(:name),
              potential_time_saving: estimate_time_saving(phase, potential_parallel)
            }
          end
        end
        
        suggestions
      end

      def resource_optimization_suggestions
        suggestions = []
        
        # Check for underutilized resources
        project.available_stakeholders.each do |stakeholder|
          task_count = stakeholder.tasks.where(status: ['pending', 'in_progress']).count
          if task_count < 2
            suggestions << {
              type: 'resource_utilization',
              resource: stakeholder.name,
              current_tasks: task_count,
              recommendation: 'Consider assigning more tasks to optimize resource utilization'
            }
          end
        end
        
        suggestions
      end

      def buffer_time_suggestions
        suggestions = []
        
        critical_phases = project.critical_phases
        critical_phases.each do |phase|
          if phase.tasks.any? && !has_buffer_time?(phase)
            suggestions << {
              type: 'buffer_time',
              phase: phase.name,
              recommendation: 'Add buffer time to critical phase to handle unexpected delays',
              suggested_buffer: calculate_suggested_buffer(phase)
            }
          end
        end
        
        suggestions
      end

      def phases_overlap?(phase1, phase2)
        return false unless phase1.start_date && phase1.end_date && phase2.start_date && phase2.end_date
        
        phase1.start_date <= phase2.end_date && phase2.start_date <= phase1.end_date
      end

      def estimate_time_saving(phase, parallel_phases)
        # Simple estimation based on non-overlapping duration
        max_duration = parallel_phases.map { |p| phase_duration(p) }.max || 0
        [phase_duration(phase), max_duration].min
      end

      def phase_duration(phase)
        return 0 unless phase.start_date && phase.end_date
        (phase.end_date - phase.start_date).to_i
      end

      def has_buffer_time?(phase)
        return false unless phase.end_date
        
        # Check if there's a gap before dependent phases start
        dependent_phases = phase.dependent_phases
        return true if dependent_phases.empty?
        
        earliest_dependent_start = dependent_phases.map(&:start_date).compact.min
        return false unless earliest_dependent_start
        
        (earliest_dependent_start - phase.end_date).to_i > 0
      end

      def calculate_suggested_buffer(phase)
        # Suggest 10% of phase duration as buffer, minimum 2 days
        duration = phase_duration(phase)
        [(duration * 0.1).round, 2].max
      end

      def calculate_overall_delay
        return 0 unless project.end_date
        
        # Find the latest ending phase
        latest_phase_end = project.phases.maximum(:end_date)
        return 0 unless latest_phase_end
        
        delay = (latest_phase_end - project.end_date).to_i
        [delay, 0].max
      end

      def calculate_phase_delays
        project.phases.map do |phase|
          delay = calculate_phase_delay(phase)
          next if delay <= 0
          
          {
            phase: phase.name,
            planned_end: phase.end_date,
            actual_or_projected_end: phase.actual_end_date || Date.current,
            delay_days: delay,
            status: phase.status
          }
        end.compact
      end

      def calculate_phase_delay(phase)
        return 0 unless phase.end_date
        
        if phase.status == 'completed' && phase.actual_end_date
          (phase.actual_end_date - phase.end_date).to_i
        elsif phase.status != 'completed' && Date.current > phase.end_date
          (Date.current - phase.end_date).to_i
        else
          0
        end
      end

      def calculate_milestone_delays
        project.milestones.map do |milestone|
          if milestone.status != 'completed' && milestone.target_date < Date.current
            {
              milestone: milestone.name,
              target_date: milestone.target_date,
              delay_days: (Date.current - milestone.target_date).to_i,
              phase: milestone.phase.name
            }
          end
        end.compact
      end

      def calculate_cascading_impacts
        delayed_phases = project.phases.select(&:is_delayed?)
        impacts = []
        
        delayed_phases.each do |phase|
          affected_phases = find_dependent_phases(phase)
          if affected_phases.any?
            impacts << {
              delayed_phase: phase.name,
              delay_days: calculate_phase_delay(phase),
              affected_phases: affected_phases.map(&:name),
              total_impact_days: estimate_total_impact(phase, affected_phases)
            }
          end
        end
        
        impacts
      end

      def find_dependent_phases(phase)
        phase.dependent_phases.includes(:dependent_phases)
      end

      def calculate_required_shift(affected_phase, triggering_phase, new_start_date)
        return 0 unless affected_phase.start_date && triggering_phase.end_date
        
        # Calculate when the triggering phase will now end
        duration = phase_duration(triggering_phase)
        new_end_date = new_start_date + duration.days
        
        # Check if affected phase needs to be shifted
        if affected_phase.prerequisite_phases.include?(triggering_phase)
          shift_needed = (new_end_date - affected_phase.start_date).to_i
          [shift_needed, 0].max
        else
          0
        end
      end

      def estimate_total_impact(delayed_phase, affected_phases)
        delay = calculate_phase_delay(delayed_phase)
        
        # Simple estimation: assume delay propagates to all dependent phases
        affected_phases.count * delay
      end
    end
  end
end