module Immo
  module Promo
    class StakeholderAllocationService
      include Concerns::AllocationOptimizer
      include Concerns::TaskCoordinator
      include Concerns::ConflictDetector
      include Concerns::AllocationAnalyzer
      
      attr_reader :project

      def initialize(project)
        @project = project
      end

      # Methods from concerns:
      # - optimize_team_allocation (AllocationOptimizer)
      # - optimize_resource_allocation (AllocationOptimizer)
      # - suggest_stakeholder_for_task (TaskCoordinator)
      # - coordinate_interventions (TaskCoordinator)
      # - forecast_completion (TaskCoordinator)
      # - detect_conflicts (ConflictDetector)
      # - active_interventions (ConflictDetector)
      # - upcoming_interventions (ConflictDetector)
      # - task_distribution (AllocationAnalyzer)
      # - recommendations (AllocationAnalyzer)
      # - resource_recommendations (AllocationAnalyzer)
      # - schedule_recommendations (AllocationAnalyzer)
      # - optimization_suggestions (AllocationAnalyzer)

      # Private methods are now in the included concerns
    end
  end
end