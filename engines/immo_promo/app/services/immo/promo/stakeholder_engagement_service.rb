module Immo
  module Promo
    class StakeholderEngagementService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def track_stakeholder_engagement(stakeholder = nil)
        if stakeholder
          track_individual_engagement(stakeholder)
        else
          track_all_engagements
        end
      end

      def identify_key_stakeholders
        {
          by_task_count: top_stakeholders_by_task_count,
          by_contract_value: top_stakeholders_by_contract_value,
          critical: critical_stakeholders
        }
      end

      def generate_contact_sheet(active_only: false)
        stakeholders = active_only ? project.stakeholders.active : project.stakeholders
        
        stakeholders.order(:stakeholder_type, :name).map(&:contact_sheet_info)
      end

      def coordination_matrix
        matrix = {}
        collaboration_points = []
        
        # Initialize matrix
        project.stakeholders.each { |sh| matrix[sh.id] = [] }
        
        # Find task dependencies between stakeholders
        analyze_task_dependencies(matrix, collaboration_points)
        
        # Add collaboration points from matrix
        matrix[:collaboration_points] = collaboration_points
        
        matrix
      end

      private

      def track_individual_engagement(stakeholder)
        tasks = stakeholder.tasks
        contracts = stakeholder.contracts
        
        tasks_data = calculate_task_statistics(tasks)
        contracts_data = calculate_contract_statistics(contracts)
        
        {
          tasks: tasks_data,
          contracts: contracts_data,
          engagement_score: stakeholder.engagement_score
        }
      end

      def track_all_engagements
        engagement_data = {}
        
        project.stakeholders.each do |stakeholder|
          engagement_data[stakeholder.id] = track_individual_engagement(stakeholder)
        end
        
        engagement_data
      end

      def calculate_task_statistics(tasks)
        {
          total: tasks.count,
          completed: tasks.where(status: 'completed').count,
          in_progress: tasks.where(status: 'in_progress').count,
          pending: tasks.where(status: 'pending').count,
          completion_rate: calculate_completion_rate(tasks)
        }
      end

      def calculate_contract_statistics(contracts)
        {
          total: contracts.count,
          active: contracts.where(status: 'active').count,
          completed: contracts.where(status: 'completed').count
        }
      end

      def calculate_completion_rate(tasks)
        return 0 if tasks.empty?
        
        completed = tasks.where(status: 'completed').count
        (completed.to_f / tasks.count * 100).round(2)
      end

      def top_stakeholders_by_task_count(limit = 5)
        project.stakeholders
               .joins(:tasks)
               .group('immo_promo_stakeholders.id')
               .order('COUNT(immo_promo_tasks.id) DESC')
               .limit(limit)
      end

      def top_stakeholders_by_contract_value(limit = 5)
        stakeholders_with_values = project.stakeholders.includes(:contracts).map do |sh|
          total_value = sh.contracts.sum(&:amount_cents) || 0
          { stakeholder: sh, contract_value: total_value }
        end
        
        stakeholders_with_values
          .sort_by { |s| -s[:contract_value] }
          .take(limit)
          .map { |s| s[:stakeholder] }
      end

      def critical_stakeholders
        project.stakeholders.where(is_primary: true)
      end

      def analyze_task_dependencies(matrix, collaboration_points)
        project.phases.includes(tasks: [:stakeholder, :prerequisite_tasks]).each do |phase|
          phase.tasks.each do |task|
            next unless task.stakeholder
            
            task.prerequisite_tasks.each do |prereq|
              next unless prereq.stakeholder
              next if task.stakeholder == prereq.stakeholder
              
              matrix[task.stakeholder.id] << prereq.stakeholder.id
              matrix[task.stakeholder.id].uniq!
              
              collaboration_points << {
                stakeholders: [prereq.stakeholder, task.stakeholder],
                reason: 'task_dependency',
                phase: phase.name,
                task: task.name
              }
            end
          end
        end
      end
    end
  end
end