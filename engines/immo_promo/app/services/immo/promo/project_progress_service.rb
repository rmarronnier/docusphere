module Immo
  module Promo
    class ProjectProgressService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def overall_progress
        @overall_progress ||= project.calculate_overall_progress
      end

      def phase_based_progress
        @phase_based_progress ||= project.calculate_phase_based_progress
      end


      def phase_progress_details
        project.phases.includes(:tasks).map do |phase|
          {
            id: phase.id,
            name: phase.name,
            type: phase.phase_type,
            status: phase.status,
            progress_percentage: phase.completion_percentage,
            weight: phase_weight(phase),
            tasks: {
              total: phase.tasks.count,
              completed: phase.tasks.where(status: 'completed').count,
              in_progress: phase.tasks.where(status: 'in_progress').count,
              pending: phase.tasks.where(status: 'pending').count
            },
            dates: {
              start: phase.start_date,
              end: phase.end_date,
              actual_start: phase.actual_start_date,
              actual_end: phase.actual_end_date
            },
            is_delayed: phase.is_delayed?,
            delay_days: calculate_phase_delay(phase)
          }
        end
      end

      def task_progress_summary
        all_tasks = Immo::Promo::Task.joins(:phase).where(phase: project.phases)
        
        {
          total: all_tasks.count,
          by_status: all_tasks.group(:status).count,
          by_priority: all_tasks.group(:priority).count,
          completion_rate: calculate_task_completion_rate(all_tasks),
          average_duration: calculate_average_task_duration(all_tasks),
          overdue_count: all_tasks.where('immo_promo_tasks.end_date < ? AND immo_promo_tasks.status != ?', Date.current, 'completed').count
        }
      end

      def milestone_progress_summary
        milestones = project.milestones
        
        {
          total: milestones.count,
          completed: milestones.where(status: 'completed').count,
          pending: milestones.where(status: 'pending').count,
          overdue: project.overdue_milestones.count,
          upcoming: project.upcoming_milestones.count,
          critical: project.critical_milestones.count,
          completion_percentage: milestone_completion_percentage(milestones)
        }
      end

      def timeline_progress
        return nil unless project.start_date && project.end_date
        
        total_duration = (project.end_date - project.start_date).to_i
        elapsed_duration = (Date.current - project.start_date).to_i
        
        {
          total_days: total_duration,
          elapsed_days: elapsed_duration,
          remaining_days: [total_duration - elapsed_duration, 0].max,
          time_progress_percentage: calculate_time_progress,
          schedule_performance_index: calculate_schedule_performance_index
        }
      end

      def progress_velocity
        # Calculate progress velocity over different time periods
        {
          daily: calculate_velocity(1.day.ago),
          weekly: calculate_velocity(1.week.ago),
          monthly: calculate_velocity(1.month.ago)
        }
      end

      def projected_completion_date
        return nil unless project.start_date
        
        current_progress = overall_progress
        return project.end_date if current_progress >= 100
        
        days_elapsed = (Date.current - project.start_date).to_i
        return nil if current_progress.zero? || days_elapsed.zero?
        
        # Simple linear projection
        total_estimated_days = (days_elapsed * 100.0 / current_progress).round
        project.start_date + total_estimated_days.days
      end

      def progress_health_status
        spi = calculate_schedule_performance_index
        
        if spi >= 0.95
          'on_track'
        elsif spi >= 0.85
          'at_risk'
        else
          'delayed'
        end
      end
      
      def phase_progress(phase)
        tasks = phase.tasks
        completed_count = tasks.where(status: 'completed').count
        total_count = tasks.count
        
        {
          phase: phase.name,
          completion_percentage: total_count > 0 ? (completed_count.to_f / total_count * 100).round(2) : 0.0,
          tasks_completed: completed_count,
          tasks_total: total_count,
          tasks_by_status: tasks.group(:status).count
        }
      end
      
      def detailed_progress_report
        {
          overall_progress: overall_progress,
          phase_based_progress: phase_based_progress,
          phases: phase_progress_details,
          critical_path_status: analyze_critical_path_status,
          milestone_status: milestone_progress_summary,
          risk_impact_on_progress: assess_risk_impact
        }
      end
      
      def milestone_progress
        milestones = project.milestones
        completed = milestones.where(status: 'completed').count
        total = milestones.count
        overdue = milestones.where('target_date < ?', Date.current).where.not(status: 'completed').count
        
        {
          total: total,
          completed: completed,
          completion_rate: total > 0 ? (completed.to_f / total * 100).round(2) : 0.0,
          overdue: overdue
        }
      end
      
      def progress_trend_analysis
        {
          current_velocity: calculate_velocity(1.week.ago),
          average_velocity: calculate_average_velocity,
          trend_direction: determine_trend_direction,
          projected_completion: projected_completion_date,
          confidence_level: calculate_confidence_level
        }
      end
      
      def identify_progress_blockers
        blockers = []
        
        # Task dependency blockers
        blocked_tasks = find_blocked_tasks
        if blocked_tasks.any?
          blockers << {
            type: 'task_dependency',
            severity: 'high',
            count: blocked_tasks.count,
            description: "#{blocked_tasks.count} tasks blocked by dependencies"
          }
        end
        
        # Resource availability blockers
        unassigned_critical = project.tasks.where(stakeholder_id: nil, priority: ['critical', 'high'])
        if unassigned_critical.any?
          blockers << {
            type: 'resource_availability',
            severity: 'high',
            count: unassigned_critical.count,
            description: "#{unassigned_critical.count} critical tasks without assigned resources"
          }
        end
        
        # Permit approval blockers
        if project.status == 'construction' && !project.can_start_construction?
          blockers << {
            type: 'permit_approval',
            severity: 'critical',
            description: 'Construction permit not approved'
          }
        end
        
        blockers
      end

      private

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

      def calculate_phase_delay(phase)
        return 0 unless phase.end_date && phase.status != 'completed'
        
        if phase.actual_end_date
          (phase.actual_end_date - phase.end_date).to_i
        elsif Date.current > phase.end_date
          (Date.current - phase.end_date).to_i
        else
          0
        end
      end

      def calculate_task_completion_rate(tasks)
        return 0 if tasks.empty?
        
        completed_count = tasks.where(status: 'completed').count
        (completed_count.to_f / tasks.count * 100).round(2)
      end

      def calculate_average_task_duration(tasks)
        completed_tasks = tasks.where(status: 'completed')
                               .where.not(actual_start_date: nil, actual_end_date: nil)
        
        return 0 if completed_tasks.empty?
        
        total_duration = completed_tasks.sum do |task|
          (task.actual_end_date - task.actual_start_date).to_i
        end
        
        (total_duration.to_f / completed_tasks.count).round(1)
      end

      def milestone_completion_percentage(milestones)
        return 0 if milestones.empty?
        
        completed = milestones.where(status: 'completed').count
        (completed.to_f / milestones.count * 100).round(2)
      end

      def calculate_time_progress
        return 0 unless project.start_date && project.end_date
        
        total_duration = (project.end_date - project.start_date).to_f
        elapsed = (Date.current - project.start_date).to_f
        
        return 100 if elapsed >= total_duration
        return 0 if elapsed < 0
        
        (elapsed / total_duration * 100).round(2)
      end

      def calculate_schedule_performance_index
        time_progress = calculate_time_progress
        actual_progress = overall_progress
        
        return 1.0 if time_progress.zero?
        
        (actual_progress / time_progress).round(2)
      end

      def calculate_velocity(since_date)
        # Calculate how much progress was made since the given date
        recent_completions = Immo::Promo::Task.joins(:phase)
                                              .where(phase: project.phases)
                                              .where(status: 'completed')
                                              .where('immo_promo_tasks.actual_end_date >= ?', since_date)
                                              .count
        
        total_tasks = project.phases.joins(:tasks).count
        return 0 if total_tasks.zero?
        
        (recent_completions.to_f / total_tasks * 100).round(2)
      end
      
      def analyze_critical_path_status
        critical_tasks = project.tasks.where(priority: 'critical')
        delayed_critical = critical_tasks.where('immo_promo_tasks.end_date < ?', Date.current)
                                       .where.not(status: 'completed')
        
        {
          total_critical_tasks: critical_tasks.count,
          delayed_critical_tasks: delayed_critical.count,
          critical_path_health: delayed_critical.empty? ? 'healthy' : 'at_risk'
        }
      end
      
      def assess_risk_impact
        high_risks = project.risks.active.high_priority
        
        impact_score = high_risks.sum do |risk|
          case risk.category
          when 'timeline' then 3
          when 'financial' then 2
          when 'quality' then 1
          else 1
          end
        end
        
        {
          active_high_risks: high_risks.count,
          risk_impact_score: impact_score,
          risk_level: impact_score > 5 ? 'high' : impact_score > 2 ? 'medium' : 'low'
        }
      end
      
      def find_blocked_tasks
        # Trouver les tâches bloquées par des dépendances non complétées
        blocked_tasks = []
        
        project.tasks.includes(:prerequisite_tasks).each do |task|
          if task.prerequisite_tasks.any? && !task.can_start?
            blocked_tasks << task
          end
        end
        
        blocked_tasks
      end
      
      def calculate_average_velocity
        velocities = []
        [1.week, 2.weeks, 3.weeks, 4.weeks].each do |period|
          velocities << calculate_velocity(period.ago)
        end
        
        velocities.sum / velocities.size.to_f
      end
      
      def determine_trend_direction
        recent_velocity = calculate_velocity(1.week.ago)
        older_velocity = calculate_velocity(2.weeks.ago)
        
        if recent_velocity > older_velocity
          'improving'
        elsif recent_velocity < older_velocity
          'declining'
        else
          'stable'
        end
      end
      
      def calculate_confidence_level
        spi = calculate_schedule_performance_index
        risk_assessment = assess_risk_impact
        
        confidence_score = 100
        confidence_score -= (1 - spi) * 50 if spi < 1
        confidence_score -= risk_assessment[:risk_impact_score] * 5
        
        case confidence_score
        when 80..100 then 'high'
        when 60..79 then 'medium'
        else 'low'
        end
      end
    end
  end
end