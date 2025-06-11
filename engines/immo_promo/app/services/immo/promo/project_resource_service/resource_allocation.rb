module Immo
  module Promo
    class ProjectResourceService
      module ResourceAllocation
        def resource_allocation_summary
          workload = stakeholder_workload_analysis
          optimization = optimize_task_assignments
          capacity = resource_capacity_planning
          
          conflicts = []
          
          # Check for overallocation
          overloaded = workload.find_all { |w| 
            percentage = w[:workload][:workload_percentage]
            percentage && percentage > 100 
          }
          if overloaded.any?
            conflicts << {
              type: 'overallocation',
              severity: 'high',
              affected_stakeholders: overloaded.map { |w| w[:stakeholder][:name] },
              description: "#{overloaded.count} stakeholders are overallocated"
            }
          end
          
          # Check for underutilization
          underutilized = workload.find_all { |w| 
            percentage = w[:workload][:workload_percentage]
            percentage && percentage < 50 
          }
          if underutilized.any?
            conflicts << {
              type: 'underutilization',
              severity: 'medium',
              affected_stakeholders: underutilized.map { |w| w[:stakeholder][:name] },
              description: "#{underutilized.count} stakeholders are underutilized"
            }
          end
          
          # Build stakeholders summary
          stakeholders_summary = {
            total: project.stakeholders.count,
            by_status: project.stakeholders.group_by { |s| s.is_active ? 'active' : 'inactive' }.transform_values(&:count),
            by_type: project.stakeholders.group(:stakeholder_type).count,
            overloaded: overloaded.count,
            available: project.stakeholders.count - overloaded.count
          }
          
          # Build phase allocation data
          phase_allocation = project.phases.map do |phase|
            tasks = phase.tasks
            allocated_stakeholders = tasks.map(&:stakeholder_id).compact.uniq
            
            {
              phase: phase.name,
              status: phase.status,
              resource_count: allocated_stakeholders.count,
              total_hours: tasks.sum(:estimated_hours),
              workload_distribution: tasks.group(:priority).count,
              phase_id: phase.id,
              phase_type: phase.phase_type,
              total_tasks: tasks.count,
              completion_percentage: phase.completion_percentage
            }
          end
          
          # Build utilization metrics
          utilizations = workload.map { |w| w[:workload][:utilization_percentage] || 0 }
          utilization_metrics = {
            average_utilization: utilizations.any? ? (utilizations.sum / utilizations.size.to_f).round(2) : 0,
            min_utilization: utilizations.min || 0,
            max_utilization: utilizations.max || 0,
            standard_deviation: calculate_standard_deviation(utilizations),
            efficiency_index: capacity[:current_capacity][:utilization_rate] || 0
          }
          
          # Check for skill mismatches
          skill_gaps = @skills_service.analyze_skills_matrix[:skill_gaps] || []
          if skill_gaps.any?
            conflicts << {
              type: 'skill_mismatch',
              severity: 'medium',
              skill_gaps: skill_gaps,
              description: "#{skill_gaps.count} required skills are missing"
            }
          end
          
          # Build recommendations
          recommendations = []
          recommendations << "Consider redistributing tasks from overloaded resources" if overloaded.any?
          recommendations << "Consider assigning more tasks to underutilized resources" if underutilized.any?
          recommendations.concat(capacity[:recommendations] || [])
          
          {
            stakeholders: stakeholders_summary,
            by_phase: phase_allocation,
            utilization_metrics: utilization_metrics,
            conflicts: conflicts,
            recommendations: recommendations,
            current_allocation: workload,
            optimization_suggestions: optimization,
            capacity_analysis: capacity
          }
        end

        def stakeholder_allocation_summary
          stakeholders = project.stakeholders.active
          
          grouped = stakeholders.group_by { |s| resource_status(calculate_utilization_percentage(s)) }
          
          {
            total: stakeholders.count,
            by_status: grouped.transform_values(&:count),
            by_type: stakeholders.group_by(&:stakeholder_type).transform_values(&:count),
            overloaded: grouped['overloaded'] || [],
            available: grouped['available'] || []
          }
        end

        def resource_allocation_by_phase
          project.phases.includes(:tasks).map do |phase|
            tasks = phase.tasks.includes(:stakeholder)
            
            {
              phase: phase.name,
              status: phase.status,
              resource_count: tasks.map(&:stakeholder).uniq.compact.count,
              total_hours: tasks.sum(&:estimated_hours),
              workload_distribution: calculate_phase_workload_distribution(tasks)
            }
          end
        end

        private

        def calculate_phase_workload_distribution(tasks)
          tasks.group_by(&:stakeholder).transform_values do |stakeholder_tasks|
            {
              task_count: stakeholder_tasks.count,
              total_hours: stakeholder_tasks.sum(&:estimated_hours)
            }
          end
        end

        def resource_status(utilization)
          case utilization
          when 0..30 then 'available'
          when 31..70 then 'partially_allocated'
          when 71..100 then 'fully_allocated'
          else 'overloaded'
          end
        end
      end
    end
  end
end