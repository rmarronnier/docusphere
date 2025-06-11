module Immo
  module Promo
    class ProjectResourceService
      module WorkloadAnalysis
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

        private

        def stakeholder_summary(stakeholder)
          {
            id: stakeholder.id,
            name: stakeholder.name,
            type: stakeholder.stakeholder_type,
            status: stakeholder.is_active ? 'active' : 'inactive'
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
          # Simple efficiency score - default since performance_rating doesn't exist
          70
        end
      end
    end
  end
end