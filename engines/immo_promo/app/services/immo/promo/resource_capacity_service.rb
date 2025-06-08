module Immo
  module Promo
    class ResourceCapacityService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def analyze_capacity
        {
          current_capacity: calculate_current_capacity,
          required_capacity: calculate_required_capacity,
          capacity_gap: calculate_capacity_gap,
          peak_periods: identify_peak_resource_periods,
          recommendations: capacity_recommendations
        }
      end

      def calculate_current_capacity
        total_capacity = project.stakeholders.active.count * 40 # 40 hours per week
        allocated_hours = project.stakeholders.active.sum do |stakeholder|
          calculate_allocated_hours(stakeholder)
        end
        
        {
          total_available: total_capacity,
          allocated: allocated_hours,
          available: total_capacity - allocated_hours,
          utilization_rate: total_capacity > 0 ? (allocated_hours.to_f / total_capacity * 100).round(2) : 0,
          by_role: capacity_by_role
        }
      end

      def calculate_required_capacity
        remaining_work = project.tasks.where.not(status: 'completed').sum(:estimated_hours)
        weeks_remaining = calculate_weeks_remaining
        
        {
          total_hours_needed: remaining_work,
          weeks_remaining: weeks_remaining,
          average_hours_per_week: weeks_remaining > 0 ? (remaining_work.to_f / weeks_remaining).round(2) : 0,
          by_phase: required_capacity_by_phase,
          critical_path_requirements: calculate_critical_path_capacity
        }
      end

      def calculate_capacity_gap
        current = calculate_current_capacity
        required = calculate_required_capacity
        
        gap = required[:average_hours_per_week] - current[:available]
        
        {
          weekly_gap: gap,
          total_gap: gap * required[:weeks_remaining],
          severity: gap > 0 ? 'shortage' : 'adequate',
          shortage_percentage: current[:available] > 0 ? (gap.to_f / current[:available] * 100).round(2) : 0,
          recommendations: gap > 0 ? generate_shortage_recommendations : []
        }
      end

      def identify_peak_resource_periods
        periods = []
        
        # Group tasks by week
        weekly_demand = Hash.new { |h, k| h[k] = { hours: 0, tasks: [] } }
        
        project.tasks.where.not(status: 'completed').each do |task|
          next unless task.start_date && task.end_date
          
          start_week = task.start_date.beginning_of_week
          end_week = task.end_date.beginning_of_week
          
          current_week = start_week
          while current_week <= end_week
            weekly_hours = calculate_weekly_hours_for_task(task, current_week)
            weekly_demand[current_week][:hours] += weekly_hours
            weekly_demand[current_week][:tasks] << task
            current_week += 1.week
          end
        end
        
        # Identify peaks
        average_demand = weekly_demand.values.sum { |d| d[:hours] } / weekly_demand.size.to_f
        
        weekly_demand.each do |week, demand|
          if demand[:hours] > average_demand * 1.2
            periods << {
              week: week,
              demand: demand[:hours],
              tasks_count: demand[:tasks].size,
              variance_from_average: ((demand[:hours] - average_demand) / average_demand * 100).round(2)
            }
          end
        end
        
        periods.sort_by { |p| -p[:demand] }
      end

      def capacity_recommendations
        recommendations = []
        gap = calculate_capacity_gap
        
        if gap[:severity] == 'shortage'
          recommendations << {
            type: 'resource_shortage',
            priority: 'high',
            message: "Project requires #{gap[:shortage_percentage]}% more resources",
            actions: [
              "Add #{(gap[:weekly_gap] / 40.0).ceil} additional resources",
              'Consider extending timeline',
              'Prioritize critical path activities'
            ]
          }
        end
        
        # Role-specific recommendations
        top_demand_roles.each do |role, demand|
          if demand[:shortage] > 0
            recommendations << {
              type: 'role_shortage',
              priority: 'medium',
              role: role,
              message: "#{role} capacity shortage of #{demand[:shortage]} hours/week",
              actions: [
                "Hire additional #{role}",
                "Cross-train existing resources",
                "Consider outsourcing"
              ]
            }
          end
        end
        
        recommendations
      end

      private

      def calculate_allocated_hours(stakeholder)
        stakeholder.tasks
                   .where(status: ['in_progress', 'pending'])
                   .sum(:estimated_hours)
      end

      def capacity_by_role
        project.stakeholders.active.group_by(&:stakeholder_type).transform_values do |stakeholders|
          stakeholders.count * 40 # 40 hours per week per stakeholder
        end
      end

      def calculate_weeks_remaining
        return 0 unless project.end_date
        weeks = ((project.end_date - Date.current) / 7.0).ceil
        [weeks, 0].max
      end

      def required_capacity_by_phase
        project.phases.includes(:tasks).map do |phase|
          {
            phase: phase.name,
            hours_needed: phase.tasks.where.not(status: 'completed').sum(:estimated_hours),
            deadline: phase.end_date,
            weeks_remaining: phase.end_date ? ((phase.end_date - Date.current) / 7.0).ceil : nil
          }
        end
      end

      def calculate_critical_path_capacity
        critical_tasks = project.tasks.where(priority: ['critical', 'high'])
        critical_tasks.where.not(status: 'completed').sum(:estimated_hours)
      end

      def generate_shortage_recommendations
        [
          'Increase resource allocation',
          'Extend project timeline',
          'Reduce scope',
          'Improve resource efficiency'
        ]
      end

      def calculate_weekly_hours_for_task(task, week_start)
        week_end = week_start + 6.days
        
        task_start = [task.start_date, week_start].max
        task_end = [task.end_date, week_end].min
        
        days_in_week = (task_end - task_start + 1).to_i
        return 0 if days_in_week <= 0
        
        total_days = (task.end_date - task.start_date + 1).to_i
        return task.estimated_hours if total_days <= 0
        
        (task.estimated_hours.to_f / total_days * days_in_week).round(2)
      end

      def top_demand_roles
        role_demand = Hash.new { |h, k| h[k] = { required: 0, available: 0 } }
        
        # Calculate required hours by role
        project.tasks.where.not(status: 'completed').includes(:stakeholder).each do |task|
          if task.stakeholder
            role = task.stakeholder.stakeholder_type
            role_demand[role][:required] += task.estimated_hours
          end
        end
        
        # Calculate available hours by role
        capacity_by_role.each do |role, capacity|
          role_demand[role][:available] = capacity
        end
        
        # Calculate shortage
        role_demand.transform_values do |demand|
          demand[:shortage] = [demand[:required] - demand[:available], 0].max
          demand
        end
      end
    end
  end
end