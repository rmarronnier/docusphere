module Immo
  module Promo
    class StakeholderAllocationService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def optimize_team_allocation
        {
          current_status: analyze_current_allocation,
          rebalancing: generate_rebalancing_recommendations,
          bottlenecks: identify_bottlenecks,
          recommendations: generate_optimization_recommendations
        }
      end

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
                                    .where(is_critical: true)
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
        poor_performers = project.stakeholders.select { |s| s.performance_rating == :poor }
        poor_performers.each do |stakeholder|
          recommendations << {
            type: :performance_improvement,
            stakeholder: stakeholder,
            action: "Envisager formation ou support supplémentaire",
            priority: :medium
          }
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

      def find_eligible_stakeholders(task)
        required_type = task_required_stakeholder_type(task)
        
        project.stakeholders
               .active
               .by_type(required_type)
               .select { |s| s.can_work_on_project? }
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
        when 'design', 'planning'
          'architect'
        when 'technical_study'
          'engineer'
        when 'construction_work'
          'contractor'
        when 'quality_control'
          'control_office'
        else
          'contractor'
        end
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
    end
  end
end