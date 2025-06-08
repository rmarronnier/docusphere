module Immo
  module Promo
    class ProjectManagerService
      attr_reader :project, :current_user

      def initialize(project, current_user = nil)
        @project = project
        @current_user = current_user
      end

      # Delegate to specialized services
      def progress_service
        @progress_service ||= ProjectProgressService.new(project)
      end

      def schedule_service
        @schedule_service ||= ProjectScheduleService.new(project)
      end

      def budget_service
        @budget_service ||= ProjectBudgetService.new(project)
      end

      def resource_service
        @resource_service ||= ProjectResourceService.new(project)
      end

      # Main coordination methods
      def calculate_overall_progress
        progress_service.overall_progress
      end

      def identify_critical_path
        schedule_service.critical_path_analysis
      end

      def calculate_critical_path
        identify_critical_path
      end

      def generate_schedule_alerts
        schedule_service.schedule_alerts
      end

      def validate_project_constraints
        errors = []
        
        # Construction readiness validation
        errors.concat(project.validate_construction_readiness)
        
        # Phase dependency validation
        errors.concat(project.validate_phase_dependencies)
        
        # Budget validation
        if project.is_over_budget?
          errors << "Budget exceeded: #{project.current_budget.format} / #{project.total_budget.format}"
        end
        
        # Resource conflicts
        resource_conflicts = resource_service.resource_conflict_calendar
        resource_conflicts.each do |conflict|
          errors << "Resource conflict: #{conflict[:stakeholder]} - #{conflict[:type]}"
        end
        
        errors
      end

      def generate_progress_report
        {
          project: project_summary,
          date: Date.current,
          progress: progress_service.detailed_progress_report,
          schedule: {
            critical_path: schedule_service.critical_path_analysis,
            alerts: schedule_service.schedule_alerts,
            delays: schedule_service.calculate_project_delays
          },
          budget: budget_service.budget_summary,
          resources: resource_service.resource_allocation_summary,
          constraints: validate_project_constraints,
          recommendations: compile_recommendations
        }
      end

      def generate_project_report
        {
          project_info: project_summary,
          progress: progress_service.detailed_progress_report,
          financial_status: budget_service.cost_tracking_report,
          schedule_status: {
            critical_path: schedule_service.critical_path_analysis,
            timeline: schedule_service.gantt_chart_data,
            delays: schedule_service.calculate_project_delays
          },
          resource_status: resource_service.stakeholder_workload_analysis,
          risks: project.active_risks.map { |r| format_risk(r) },
          milestones: format_milestones
        }
      end

      def update_project_timeline(phase, new_start_date)
        rescheduling_plan = schedule_service.reschedule_from_phase(phase, new_start_date)
        
        # Apply the rescheduling plan
        ActiveRecord::Base.transaction do
          # Update the main phase
          phase.update!(start_date: new_start_date)
          
          # Update cascading phases
          rescheduling_plan[:cascading_updates].each do |update|
            update[:phase].update!(start_date: update[:new_start])
          end
        end
        
        rescheduling_plan
      end

      def assign_resources(task, assignee)
        # Validate assignment feasibility
        if resource_service.send(:can_handle_task?, assignee, task)
          task.update!(assigned_to: assignee)
          {
            success: true,
            new_workload: resource_service.send(:calculate_stakeholder_workload, assignee)
          }
        else
          {
            success: false,
            reason: 'Assignee lacks capacity or required skills',
            required_skills: task.required_skills,
            assignee_skills: assignee.respond_to?(:skills) ? assignee.skills : []
          }
        end
      end

      def track_budget_usage
        budget_service.budget_summary
      end

      def critical_path_analysis
        schedule_service.critical_path_analysis
      end

      def optimize_resource_allocation
        resource_service.optimize_task_assignments
      end

      # Executive dashboard data
      def executive_dashboard
        {
          key_metrics: {
            overall_progress: progress_service.overall_progress,
            budget_usage: project.budget_usage_percentage,
            schedule_health: progress_service.progress_health_status,
            resource_utilization: resource_service.calculate_utilization_metrics[:overall_utilization]
          },
          alerts: compile_all_alerts,
          critical_items: {
            overdue_milestones: project.overdue_milestones.count,
            at_risk_phases: project.phases.select(&:is_delayed?).count,
            budget_overruns: budget_service.send(:identify_cost_overruns).count,
            resource_conflicts: resource_service.identify_resource_conflicts.count
          },
          trends: {
            progress_velocity: progress_service.progress_velocity,
            burn_rate: budget_service.send(:calculate_burn_rate),
            projected_completion: progress_service.projected_completion_date
          }
        }
      end

      # Risk assessment
      def risk_assessment
        {
          schedule_risks: assess_schedule_risks,
          budget_risks: assess_budget_risks,
          resource_risks: assess_resource_risks,
          overall_risk_score: calculate_overall_risk_score,
          mitigation_strategies: suggest_mitigation_strategies
        }
      end

      private

      def project_summary
        {
          id: project.id,
          name: project.name,
          reference: project.reference_number,
          type: project.project_type,
          status: project.status,
          manager: project.project_manager&.full_name,
          organization: project.organization.name,
          dates: {
            start: project.start_date,
            end: project.end_date,
            duration_days: project.start_date && project.end_date ? (project.end_date - project.start_date).to_i : nil
          },
          location: {
            address: project.address,
            city: project.city,
            postal_code: project.postal_code
          }
        }
      end

      def compile_recommendations
        recommendations = []
        
        # Progress recommendations
        if progress_service.progress_health_status == 'delayed'
          recommendations << {
            category: 'progress',
            priority: 'high',
            message: 'Project is behind schedule. Consider resource reallocation or timeline adjustment.'
          }
        end
        
        # Budget recommendations
        budget_service.budget_optimization_suggestions.each do |suggestion|
          recommendations << {
            category: 'budget',
            priority: 'medium',
            message: suggestion[:recommendation],
            details: suggestion
          }
        end
        
        # Schedule recommendations
        schedule_service.timeline_optimization_suggestions.each do |suggestion|
          recommendations << {
            category: 'schedule',
            priority: 'medium',
            message: suggestion[:recommendation] || "Optimization opportunity: #{suggestion[:type]}",
            details: suggestion
          }
        end
        
        # Resource recommendations
        resource_service.optimization_recommendations.each do |rec|
          recommendations << {
            category: 'resources',
            priority: rec[:priority],
            message: rec[:description],
            action: rec[:action]
          }
        end
        
        recommendations.sort_by { |r| recommendation_priority(r[:priority]) }
      end

      def recommendation_priority(priority)
        case priority
        when 'high' then 1
        when 'medium' then 2
        when 'low' then 3
        else 4
        end
      end

      def compile_all_alerts
        alerts = []
        
        # Schedule alerts
        alerts.concat(schedule_service.schedule_alerts)
        
        # Budget alerts
        alerts.concat(budget_service.budget_alerts)
        
        # Resource alerts (convert conflicts to alerts)
        resource_service.identify_resource_conflicts.each do |conflict|
          alerts << {
            type: conflict[:severity] == 'high' ? 'danger' : 'warning',
            category: 'resource',
            title: conflict[:type].humanize,
            message: "#{conflict[:resource]} - #{conflict[:type]}",
            details: conflict
          }
        end
        
        alerts
      end

      def format_risk(risk)
        {
          id: risk.id,
          title: risk.name,
          description: risk.description,
          severity: risk.severity,
          probability: risk.probability,
          impact: risk.impact,
          mitigation_plan: risk.mitigation_plan,
          owner: risk.owner&.full_name,
          status: risk.status
        }
      end

      def format_milestones
        project.milestones.includes(:phase).map do |milestone|
          {
            id: milestone.id,
            name: milestone.name,
            phase: milestone.phase.name,
            date: milestone.target_date,
            status: milestone.status,
            is_critical: milestone.is_critical?,
            is_overdue: milestone.target_date < Date.current && milestone.status != 'completed'
          }
        end
      end

      def assess_schedule_risks
        risks = []
        
        # Critical path delays
        if project.has_critical_path_delays?
          risks << {
            type: 'critical_path_delay',
            severity: 'high',
            description: 'Critical path activities are delayed',
            impact: 'Project completion date at risk'
          }
        end
        
        # Resource availability
        if resource_service.identify_resource_conflicts.any? { |c| c[:type] == 'availability_conflict' }
          risks << {
            type: 'resource_availability',
            severity: 'medium',
            description: 'Key resources have availability conflicts',
            impact: 'Potential task delays'
          }
        end
        
        risks
      end

      def assess_budget_risks
        risks = []
        
        # Budget overrun risk
        if project.budget_usage_percentage > 80 && progress_service.overall_progress < 70
          risks << {
            type: 'budget_overrun',
            severity: 'high',
            description: 'High budget consumption with low progress',
            impact: 'Project may exceed budget before completion'
          }
        end
        
        # High burn rate
        if budget_service.send(:high_burn_rate?)
          risks << {
            type: 'high_burn_rate',
            severity: 'medium',
            description: 'Spending rate exceeds planned rate',
            impact: 'Budget exhaustion before project completion'
          }
        end
        
        risks
      end

      def assess_resource_risks
        risks = []
        
        # Skill gaps
        skill_gaps = resource_service.send(:identify_skill_gaps)
        if skill_gaps.any?
          risks << {
            type: 'skill_gap',
            severity: 'medium',
            description: "Missing critical skills: #{skill_gaps.join(', ')}",
            impact: 'Quality issues or delays in specialized tasks'
          }
        end
        
        # Over-reliance on key resources
        critical_resources = identify_critical_resource_dependencies
        if critical_resources.any?
          risks << {
            type: 'key_person_dependency',
            severity: 'medium',
            description: "Over-reliance on: #{critical_resources.join(', ')}",
            impact: 'Project vulnerable to resource unavailability'
          }
        end
        
        risks
      end

      def identify_critical_resource_dependencies
        # Find resources assigned to many critical tasks
        critical_assignees = Immo::Promo::Task.joins(:phase)
                                              .where(phase: project.phases, priority: 'critical')
                                              .where.not(assigned_to_id: nil)
                                              .group(:assigned_to_id)
                                              .having('COUNT(*) > 3')
                                              .includes(:assigned_to)
                                              .map { |t| t.assigned_to.full_name }
                                              .uniq
      end

      def calculate_overall_risk_score
        all_risks = []
        all_risks.concat(assess_schedule_risks)
        all_risks.concat(assess_budget_risks)
        all_risks.concat(assess_resource_risks)
        
        return 'low' if all_risks.empty?
        
        high_risks = all_risks.count { |r| r[:severity] == 'high' }
        medium_risks = all_risks.count { |r| r[:severity] == 'medium' }
        
        if high_risks >= 2 || (high_risks >= 1 && medium_risks >= 2)
          'high'
        elsif high_risks >= 1 || medium_risks >= 2
          'medium'
        else
          'low'
        end
      end

      def suggest_mitigation_strategies
        strategies = []
        
        # Schedule mitigation
        if project.has_critical_path_delays?
          strategies << {
            risk_type: 'schedule',
            strategy: 'Fast-track non-critical activities or add resources to critical path',
            priority: 'high'
          }
        end
        
        # Budget mitigation
        if project.budget_usage_percentage > 80
          strategies << {
            risk_type: 'budget',
            strategy: 'Implement cost control measures and review scope for potential reductions',
            priority: 'high'
          }
        end
        
        # Resource mitigation
        if resource_service.send(:needs_load_balancing?)
          strategies << {
            risk_type: 'resource',
            strategy: 'Redistribute workload and consider bringing in additional resources',
            priority: 'medium'
          }
        end
        
        strategies
      end
    end
  end
end
