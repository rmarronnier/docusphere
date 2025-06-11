module Immo
  module Promo
    class ProjectResourceService
      module OptimizationRecommendations
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

        def optimize_task_assignments
          @optimization_service.optimize_assignments
        end

        def skill_matrix_analysis
          @skills_service.analyze_skills_matrix
        end

        private

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
      end
    end
  end
end