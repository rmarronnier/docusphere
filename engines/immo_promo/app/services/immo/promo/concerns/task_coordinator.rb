module Immo
  module Promo
    module Concerns
      module TaskCoordinator
        extend ActiveSupport::Concern

        def suggest_stakeholder_for_task(task)
          eligible_stakeholders = find_eligible_stakeholders(task)
          
          return nil if eligible_stakeholders.empty?
          
          # Trier par disponibilité et compétence
          eligible_stakeholders.sort_by do |stakeholder|
            [
              workload_score(stakeholder),
              -performance_score(stakeholder),
              conflicts_score(stakeholder, task)
            ]
          end.first
        end

        def coordinate_interventions
          coordination_plan = []
          
          project.phases.includes(:tasks).order(:position).each do |phase|
            phase_coordination = coordinate_phase_interventions(phase)
            coordination_plan << phase_coordination if phase_coordination[:tasks].any?
          end
          
          {
            phases: coordination_plan,
            conflicts: identify_scheduling_conflicts,
            optimization_suggestions: suggest_schedule_optimizations
          }
        end

        def forecast_completion
          phases = project.phases.includes(:tasks)
          critical_path = identify_critical_path
          
          latest_date = critical_path.map(&:end_date).compact.max || project.end_date
          
          {
            forecast_date: latest_date,
            confidence_level: calculate_forecast_confidence,
            critical_path: critical_path.map(&:id),
            risk_factors: {
              resource_availability: assess_resource_risk,
              weather_impact: 'low',
              dependency_risks: assess_dependency_risk
            }
          }
        end

        private

        def find_eligible_stakeholders(task)
          required_type = task_required_stakeholder_type(task)
          
          project.stakeholders
                 .active
                 .by_type(required_type)
                 .select { |s| s.can_work_on_project? }
        end

        def coordinate_phase_interventions(phase)
          {
            phase: phase,
            tasks: phase.tasks.includes(:stakeholder, :assigned_to).map do |task|
              {
                task: task,
                stakeholder: task.stakeholder,
                assigned_user: task.assigned_to,
                dependencies: task.prerequisite_tasks.pluck(:name),
                coordination_required: task_requires_coordination?(task)
              }
            end
          }
        end

        def identify_scheduling_conflicts
          conflicts = []
          
          project.stakeholders.each do |stakeholder|
            overlapping_tasks = find_overlapping_tasks(stakeholder)
            
            if overlapping_tasks.any?
              conflicts << {
                stakeholder: stakeholder,
                tasks: overlapping_tasks,
                type: :task_overlap,
                severity: :high
              }
            end
          end
          
          conflicts
        end

        def find_overlapping_tasks(stakeholder)
          tasks = stakeholder.tasks.where(status: ['pending', 'in_progress'])
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

        def suggest_schedule_optimizations
          suggestions = []
          
          # Suggérer de paralléliser les tâches indépendantes
          independent_tasks = find_independent_tasks_by_phase
          independent_tasks.each do |phase, tasks|
            if tasks.count > 1
              suggestions << {
                type: :parallelization,
                phase: phase,
                tasks: tasks,
                potential_time_saving: estimate_time_saving(tasks)
              }
            end
          end
          
          suggestions
        end

        def find_independent_tasks_by_phase
          independent = {}
          
          project.phases.each do |phase|
            phase_tasks = phase.tasks.where(status: 'pending')
            independent_tasks = phase_tasks.select { |t| t.prerequisite_tasks.empty? }
            
            independent[phase] = independent_tasks if independent_tasks.any?
          end
          
          independent
        end

        def estimate_time_saving(tasks)
          return 0 if tasks.empty?
          
          sequential_duration = tasks.sum { |t| (t.end_date - t.start_date).to_i }
          parallel_duration = tasks.map { |t| (t.end_date - t.start_date).to_i }.max
          
          sequential_duration - parallel_duration
        end

        def task_required_stakeholder_type(task)
          case task.task_type
          when 'planning'
            'architect'
          when 'technical'
            'engineer'
          when 'execution'
            'contractor'
          when 'review', 'approval'
            'control_office'
          else
            'contractor'
          end
        end

        def task_requires_coordination?(task)
          task.prerequisite_tasks.any? || task.dependent_tasks.any?
        end

        def workload_score(stakeholder)
          case stakeholder.workload_status
          when :available then 0
          when :partially_available then 1
          when :busy then 2
          when :overloaded then 3
          else 4
          end
        end

        def performance_score(stakeholder)
          case stakeholder.performance_rating
          when :excellent then 4
          when :good then 3
          when :average then 2
          when :below_average then 1
          when :poor then 0
          else 1
          end
        end

        def conflicts_score(stakeholder, task)
          stakeholder.has_conflicting_tasks?(task) ? 1 : 0
        end

        def identify_critical_path
          # Simplified critical path - just return high priority tasks
          critical_tasks = project.tasks.where(priority: ['critical', 'high'])
          
          if critical_tasks.empty?
            project.tasks.limit(1)
          else
            critical_tasks
          end
        end

        def calculate_forecast_confidence
          progress = project.calculate_overall_progress
          
          case progress
          when 0..20 then 40
          when 21..50 then 65
          when 51..80 then 80
          else 90
          end
        end

        def assess_resource_risk
          overloaded_count = project.stakeholders.overloaded.count
          
          case overloaded_count
          when 0 then 'low'
          when 1..2 then 'medium'
          else 'high'
          end
        end

        def assess_dependency_risk
          tasks_with_dependencies = project.tasks.joins(:task_dependencies).distinct.count
          total_tasks = project.tasks.count
          
          return 'low' if total_tasks.zero?
          
          dependency_ratio = tasks_with_dependencies.to_f / total_tasks
          
          case dependency_ratio
          when 0..0.3 then 'low'
          when 0.3..0.6 then 'medium'
          else 'high'
          end
        end
      end
    end
  end
end