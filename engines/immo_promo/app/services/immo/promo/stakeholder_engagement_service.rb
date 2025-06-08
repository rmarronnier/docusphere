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
      
      def analyze_performance(stakeholder)
        tasks = stakeholder.tasks
        completed_tasks = tasks.where(status: 'completed')
        
        {
          total_tasks: tasks.count,
          completed_tasks: completed_tasks.count,
          on_time_rate: calculate_on_time_rate(completed_tasks),
          quality_score: calculate_quality_score(stakeholder),
          response_time: calculate_average_response_time(stakeholder),
          collaboration_score: calculate_collaboration_score(stakeholder),
          overall_rating: stakeholder.performance_rating
        }
      end
      
      def stakeholder_overview
        {
          total: project.stakeholders.count,
          by_type: project.stakeholders.group_by(&:stakeholder_type).transform_values(&:count),
          by_status: project.stakeholders.group_by { |s| s.is_active ? 'active' : 'inactive' }.transform_values(&:count)
        }
      end
      
      def performance_metrics
        stakeholders = project.stakeholders
        
        # Calculate performance ratings for all stakeholders
        ratings = stakeholders.map(&:performance_rating)
        top_performers = ratings.count { |r| ['excellent', 'good'].include?(r.to_s) }
        under_performers = ratings.count { |r| ['below_average', 'poor'].include?(r.to_s) }
        
        {
          average_performance: calculate_average_performance(stakeholders),
          top_performers: top_performers,
          under_performers: under_performers,
          performance_distribution: ratings.group_by(&:to_s).transform_values(&:count)
        }
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
      
      def calculate_on_time_rate(completed_tasks)
        return 0 if completed_tasks.empty?
        
        on_time = completed_tasks.select { |t| 
          t.actual_end_date && t.end_date && t.actual_end_date <= t.end_date 
        }.count
        
        (on_time.to_f / completed_tasks.count * 100).round(2)
      end
      
      def calculate_quality_score(stakeholder)
        # Simplified quality score based on performance rating
        case stakeholder.performance_rating
        when 'excellent' then 95
        when 'good' then 85
        when 'average' then 75
        when 'below_average' then 60
        when 'poor' then 40
        else 70
        end
      end
      
      def calculate_average_response_time(stakeholder)
        # Placeholder - would calculate from actual response data
        case stakeholder.performance_rating
        when 'excellent' then 1
        when 'good' then 2
        when 'average' then 3
        else 4
        end
      end
      
      def calculate_collaboration_score(stakeholder)
        # Based on number of collaborative tasks
        collaborative_tasks = stakeholder.tasks.joins(:task_dependencies).distinct.count
        total_tasks = stakeholder.tasks.count
        
        return 0 if total_tasks.zero?
        
        (collaborative_tasks.to_f / total_tasks * 100).round
      end
      
      def calculate_average_performance(stakeholders)
        return 0 if stakeholders.empty?
        
        scores = stakeholders.map { |s| calculate_quality_score(s) }
        (scores.sum / scores.count.to_f).round(2)
      end
    end
  end
end