module Immo
  module Promo
    module Concerns
      module AllocationOptimizer
        extend ActiveSupport::Concern

        def optimize_team_allocation
          {
            current_status: analyze_current_allocation,
            rebalancing: generate_rebalancing_recommendations,
            bottlenecks: identify_bottlenecks,
            recommendations: generate_optimization_recommendations
          }
        end

        def optimize_resource_allocation
          unassigned_tasks = project.tasks.where(stakeholder: nil)
          optimized_assignments = []
          
          unassigned_tasks.each do |task|
            best_stakeholder = suggest_stakeholder_for_task(task)
            
            optimized_assignments << {
              task_id: task.id,
              stakeholder_id: best_stakeholder&.id,
              reason: best_stakeholder ? 'Skills match and availability' : 'No suitable stakeholder available'
            }
          end
          
          {
            success: true,
            optimized_assignments: optimized_assignments
          }
        end

        private

        def analyze_current_allocation
          {
            overloaded: project.stakeholders.overloaded,
            underutilized: project.stakeholders.underutilized,
            balanced: find_balanced_stakeholders,
            workload_distribution: calculate_workload_distribution
          }
        end

        def generate_rebalancing_recommendations
          recommendations = []
          
          overloaded = project.stakeholders.overloaded
          underutilized = project.stakeholders.underutilized
          
          overloaded.each do |overloaded_stakeholder|
            transferable_tasks = find_transferable_tasks(overloaded_stakeholder)
            
            transferable_tasks.each do |task|
              suitable_recipient = find_suitable_recipient(task, underutilized)
              
              if suitable_recipient
                recommendations << {
                  task: task,
                  from: overloaded_stakeholder,
                  to: suitable_recipient,
                  reason: "Rééquilibrage de charge de travail",
                  impact: calculate_rebalancing_impact(task, overloaded_stakeholder, suitable_recipient)
                }
              end
            end
          end
          
          recommendations
        end

        def identify_bottlenecks
          bottlenecks = []
          
          # Identifier les stakeholders critiques surchargés
          critical_overloaded = project.stakeholders
                                      .where(is_primary: true)
                                      .overloaded
          
          critical_overloaded.each do |stakeholder|
            bottlenecks << {
              stakeholder: stakeholder,
              type: :critical_resource_overload,
              impact: "Risque de retard sur les phases critiques",
              affected_tasks: stakeholder.tasks.where(status: ['pending', 'in_progress']),
              severity: :high
            }
          end
          
          # Identifier les goulots d'étranglement par type
          stakeholder_types = project.stakeholders.group(:stakeholder_type).count
          
          stakeholder_types.each do |type, count|
            if count == 1
              bottlenecks << {
                type: :single_point_of_failure,
                stakeholder_type: type,
                impact: "Pas de redondance pour le type #{type}",
                severity: :medium
              }
            end
          end
          
          bottlenecks
        end

        def generate_optimization_recommendations
          recommendations = []
          
          # Recommandations basées sur les performances
          project.stakeholders.each do |stakeholder|
            if stakeholder.performance_rating == :poor
              recommendations << {
                type: :performance_improvement,
                stakeholder: stakeholder,
                action: "Envisager formation ou support supplémentaire",
                priority: :medium
              }
            end
          end
          
          # Recommandations pour les ressources manquantes
          missing_types = identify_missing_stakeholder_types
          missing_types.each do |type|
            recommendations << {
              type: :resource_addition,
              stakeholder_type: type,
              action: "Recruter ou sous-traiter un #{type}",
              priority: :high
            }
          end
          
          recommendations
        end

        def find_balanced_stakeholders
          project.stakeholders.select do |s|
            status = s.workload_status
            [:partially_available, :busy].include?(status)
          end
        end

        def calculate_workload_distribution
          distribution = Hash.new(0)
          
          project.stakeholders.each do |s|
            distribution[s.workload_status] += 1
          end
          
          distribution
        end

        def find_transferable_tasks(stakeholder)
          stakeholder.tasks
                     .where(status: 'pending')
                     .where('start_date > ?', 1.week.from_now)
        end

        def find_suitable_recipient(task, candidates)
          candidates.find do |candidate|
            candidate.stakeholder_type == task.stakeholder&.stakeholder_type &&
            !candidate.has_conflicting_tasks?(task) &&
            candidate.can_work_on_project?
          end
        end

        def calculate_rebalancing_impact(task, from, to)
          {
            from_workload_change: calculate_workload_change(from, -1),
            to_workload_change: calculate_workload_change(to, 1),
            schedule_impact: "Aucun impact si transféré avant le début",
            risk_level: :low
          }
        end

        def calculate_workload_change(stakeholder, task_count_change)
          current = stakeholder.workload_status
          future_count = stakeholder.tasks.where(status: ['pending', 'in_progress']).count + task_count_change
          
          future_status = case future_count
                         when 0 then :available
                         when 1..3 then :partially_available
                         when 4..6 then :busy
                         else :overloaded
                         end
          
          "#{current} → #{future_status}"
        end

        def check_workload_balance
          workloads = project.stakeholders.map { |s| s.tasks.where(status: ['pending', 'in_progress']).count }
          
          {
            needs_rebalancing: workloads.max - workloads.min > 3,
            max_workload: workloads.max,
            min_workload: workloads.min,
            average_workload: workloads.sum.to_f / workloads.count
          }
        end

        def identify_missing_stakeholder_types
          required_types = Set.new
          
          project.phases.each do |phase|
            required_types.merge(required_stakeholder_types_for_phase(phase.phase_type))
          end
          
          existing_types = project.stakeholders.pluck(:stakeholder_type).uniq
          
          required_types - existing_types
        end

        def required_stakeholder_types_for_phase(phase_type)
          case phase_type.to_s
          when 'studies'
            ['architect', 'engineer']
          when 'permits'
            ['architect']
          when 'construction'
            ['architect', 'engineer', 'contractor', 'control_office']
          when 'reception'
            ['architect', 'control_office']
          else
            []
          end
        end
      end
    end
  end
end