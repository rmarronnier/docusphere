module Immo
  module Promo
    module Concerns
      module AllocationAnalyzer
        extend ActiveSupport::Concern

        def task_distribution
          distribution = project.tasks.group(:status).count
          total = distribution.values.sum
          
          distribution.transform_values { |v| total > 0 ? (v.to_f / total * 100).round(1) : 0 }
        end

        def recommendations
          generate_optimization_recommendations
        end

        def resource_recommendations
          [
            {
              description: 'Rééquilibrer la charge de travail',
              impact: 'high',
              effort: 'medium',
              priority: 1
            }
          ]
        end

        def schedule_recommendations
          [
            {
              description: 'Optimiser le séquencement des tâches',
              impact: 'medium',
              effort: 'low',
              priority: 2
            }
          ]
        end

        def optimization_suggestions
          suggestions = []
          
          # Suggest load balancing
          workload_imbalance = check_workload_balance
          if workload_imbalance[:needs_rebalancing]
            suggestions << {
              type: 'load_balancing',
              description: 'Rééquilibrer la charge de travail entre intervenants',
              priority: 'high',
              details: workload_imbalance
            }
          end
          
          # Suggest task grouping
          groupable_tasks = find_groupable_tasks
          if groupable_tasks.any?
            suggestions << {
              type: 'task_grouping',
              description: 'Regrouper les tâches par phase pour optimiser les déplacements',
              priority: 'medium',
              tasks: groupable_tasks
            }
          end
          
          # Always provide at least one suggestion
          if suggestions.empty?
            suggestions << {
              type: 'general_optimization',
              description: 'Optimiser la planification des interventions',
              priority: 'low'
            }
          end
          
          suggestions
        end

        private

        def check_workload_balance
          workloads = project.stakeholders.map { |s| s.tasks.where(status: ['pending', 'in_progress']).count }
          
          {
            needs_rebalancing: workloads.max - workloads.min > 3,
            max_workload: workloads.max,
            min_workload: workloads.min,
            average_workload: workloads.sum.to_f / workloads.count
          }
        end

        def find_groupable_tasks
          tasks_by_phase = project.tasks.where(status: 'pending').group_by(&:phase)
          
          groupable = []
          tasks_by_phase.each do |phase, tasks|
            if tasks.count > 1
              groupable << {
                phase: phase.name,
                tasks: tasks.map(&:name),
                potential_efficiency_gain: "#{tasks.count * 10}%"
              }
            end
          end
          
          groupable
        end
      end
    end
  end
end