module Immo
  module Promo
    class ProjectBudgetService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def budget_summary
        {
          allocated: project.total_budget,
          used: project.current_budget,
          remaining: project.remaining_budget,
          percentage_used: project.budget_usage_percentage,
          is_over_budget: project.is_over_budget?,
          budgets: detailed_budget_breakdown,
          forecast: budget_forecast,
          alerts: budget_alerts
        }
      end

      def detailed_budget_breakdown
        project.budgets.includes(:budget_lines).map do |budget|
          {
            id: budget.id,
            category: budget.budget_type || 'general',
            fiscal_year: budget.fiscal_year,
            lines: budget_lines_summary(budget),
            totals: calculate_budget_totals(budget),
            variance_analysis: variance_analysis(budget)
          }
        end
      end

      def cost_tracking_report
        {
          by_phase: costs_by_phase,
          by_category: costs_by_category,
          by_period: costs_by_period,
          top_expenses: top_expense_items,
          cost_overruns: identify_cost_overruns
        }
      end

      def budget_forecast
        current_burn_rate = calculate_burn_rate
        months_remaining = calculate_months_remaining
        
        {
          current_burn_rate: current_burn_rate,
          projected_total_cost: project_total_cost(current_burn_rate, months_remaining),
          projected_completion_budget: project.current_budget + (current_burn_rate * months_remaining),
          confidence_level: calculate_forecast_confidence,
          scenarios: {
            optimistic: forecast_scenario(0.8),
            realistic: forecast_scenario(1.0),
            pessimistic: forecast_scenario(1.2)
          }
        }
      end

      def budget_optimization_suggestions
        suggestions = []
        
        # Check for categories with high variance
        suggestions.concat(high_variance_suggestions)
        
        # Check for potential savings
        suggestions.concat(cost_saving_opportunities)
        
        # Check for budget reallocation opportunities
        suggestions.concat(reallocation_suggestions)
        
        suggestions
      end

      def cash_flow_analysis
        {
          monthly_cash_flow: calculate_monthly_cash_flow,
          cumulative_spending: calculate_cumulative_spending,
          payment_schedule: payment_schedule_summary,
          liquidity_requirements: calculate_liquidity_needs
        }
      end

      private

      def budget_lines_summary(budget)
        budget.budget_lines.map do |line|
          {
            id: line.id,
            description: line.description,
            category: line.category,
            planned: Money.new(line.planned_amount_cents || 0, 'EUR'),
            actual: Money.new(line.actual_amount_cents || 0, 'EUR'),
            committed: Money.new(line.committed_amount_cents || 0, 'EUR'),
            variance: calculate_line_variance(line),
            variance_percentage: calculate_line_variance_percentage(line)
          }
        end
      end

      def calculate_budget_totals(budget)
        totals = budget.budget_lines.reduce({ planned: 0, actual: 0, committed: 0 }) do |sum, line|
          {
            planned: sum[:planned] + (line.planned_amount_cents || 0),
            actual: sum[:actual] + (line.actual_amount_cents || 0),
            committed: sum[:committed] + (line.committed_amount_cents || 0)
          }
        end
        
        {
          planned: Money.new(totals[:planned], 'EUR'),
          actual: Money.new(totals[:actual], 'EUR'),
          committed: Money.new(totals[:committed], 'EUR'),
          available: Money.new(totals[:planned] - totals[:actual] - totals[:committed], 'EUR')
        }
      end

      def variance_analysis(budget)
        totals = calculate_budget_totals(budget)
        variance = totals[:planned] - totals[:actual]
        variance_percentage = totals[:planned].zero? ? 0 : (variance.to_f / totals[:planned] * 100).round(2)
        
        {
          amount: variance,
          percentage: variance_percentage,
          status: variance_status(variance_percentage),
          trend: calculate_variance_trend(budget)
        }
      end

      def calculate_line_variance(line)
        planned = Money.new(line.planned_amount_cents || 0, 'EUR')
        actual = Money.new(line.actual_amount_cents || 0, 'EUR')
        planned - actual
      end

      def calculate_line_variance_percentage(line)
        return 0 if line.planned_amount_cents.nil? || line.planned_amount_cents.zero?
        
        variance = line.planned_amount_cents - (line.actual_amount_cents || 0)
        (variance.to_f / line.planned_amount_cents * 100).round(2)
      end

      def variance_status(percentage)
        if percentage >= -5
          'on_track'
        elsif percentage >= -15
          'warning'
        else
          'critical'
        end
      end

      def calculate_variance_trend(budget)
        # Simplified trend calculation
        # In a real implementation, would analyze historical data
        'stable'
      end

      def costs_by_phase
        phase_costs = {}
        
        project.phases.each do |phase|
          phase_costs[phase.name] = {
            budgeted: calculate_phase_budget(phase),
            actual: calculate_phase_actual_cost(phase),
            committed: calculate_phase_committed_cost(phase),
            status: phase.status
          }
        end
        
        phase_costs
      end

      def costs_by_category
        category_costs = Hash.new { |h, k| h[k] = { planned: 0, actual: 0, committed: 0 } }
        
        project.budgets.includes(:budget_lines).each do |budget|
          budget.budget_lines.each do |line|
            category = line.category || 'uncategorized'
            category_costs[category][:planned] += line.planned_amount_cents || 0
            category_costs[category][:actual] += line.actual_amount_cents || 0
            category_costs[category][:committed] += line.committed_amount_cents || 0
          end
        end
        
        category_costs.transform_values do |amounts|
          {
            planned: Money.new(amounts[:planned], 'EUR'),
            actual: Money.new(amounts[:actual], 'EUR'),
            committed: Money.new(amounts[:committed], 'EUR')
          }
        end
      end

      def costs_by_period
        # Group costs by month
        monthly_costs = Hash.new { |h, k| h[k] = { planned: 0, actual: 0 } }
        
        project.budgets.includes(:budget_lines).each do |budget|
          month_key = "#{budget.fiscal_year}-#{budget.created_at.month.to_s.rjust(2, '0')}"
          
          budget.budget_lines.each do |line|
            monthly_costs[month_key][:planned] += line.planned_amount_cents || 0
            monthly_costs[month_key][:actual] += line.actual_amount_cents || 0
          end
        end
        
        monthly_costs.transform_values do |amounts|
          {
            planned: Money.new(amounts[:planned], 'EUR'),
            actual: Money.new(amounts[:actual], 'EUR')
          }
        end.sort.to_h
      end

      def top_expense_items(limit = 10)
        all_lines = project.budgets.includes(:budget_lines).flat_map(&:budget_lines)
        
        all_lines.sort_by { |line| -(line.actual_amount_cents || 0) }
                 .first(limit)
                 .map do |line|
          {
            description: line.description,
            category: line.category,
            amount: Money.new(line.actual_amount_cents || 0, 'EUR'),
            budget: line.budget.category,
            variance: calculate_line_variance_percentage(line)
          }
        end
      end

      def identify_cost_overruns
        overruns = []
        
        project.budgets.includes(:budget_lines).each do |budget|
          budget.budget_lines.each do |line|
            next unless line.actual_amount_cents && line.planned_amount_cents
            next unless line.actual_amount_cents > line.planned_amount_cents
            
            overrun_amount = line.actual_amount_cents - line.planned_amount_cents
            overrun_percentage = (overrun_amount.to_f / line.planned_amount_cents * 100).round(2)
            
            overruns << {
              budget: budget.category,
              line: line.description,
              category: line.category,
              overrun_amount: Money.new(overrun_amount, 'EUR'),
              overrun_percentage: overrun_percentage,
              severity: overrun_severity(overrun_percentage)
            }
          end
        end
        
        overruns.sort_by { |o| -o[:overrun_percentage] }
      end

      def overrun_severity(percentage)
        if percentage <= 10
          'low'
        elsif percentage <= 25
          'medium'
        else
          'high'
        end
      end

      def calculate_burn_rate
        return Money.new(0, 'EUR') unless project.start_date
        
        months_elapsed = ((Date.current - project.start_date) / 30.0).round(1)
        return Money.new(0, 'EUR') if months_elapsed <= 0
        
        project.current_budget / months_elapsed
      end

      def calculate_months_remaining
        return 0 unless project.end_date
        
        months = ((project.end_date - Date.current) / 30.0).round(1)
        [months, 0].max
      end

      def project_total_cost(burn_rate, months_remaining)
        project.current_budget + (burn_rate * months_remaining)
      end

      def calculate_forecast_confidence
        # Based on project progress and historical accuracy
        progress = project.calculate_overall_progress
        
        if progress < 20
          'low'
        elsif progress < 60
          'medium'
        else
          'high'
        end
      end

      def forecast_scenario(factor)
        burn_rate = calculate_burn_rate
        months_remaining = calculate_months_remaining
        
        {
          burn_rate: burn_rate * factor,
          total_cost: project_total_cost(burn_rate * factor, months_remaining),
          budget_variance: begin
            project_total_cost(burn_rate * factor, months_remaining) - project.total_budget
          rescue
            nil
          end
        }
      end

      def budget_alerts
        alerts = []
        
        # Over budget alert
        if project.is_over_budget?
          alerts << {
            type: 'danger',
            title: 'Budget Exceeded',
            message: "Project is #{project.budget_usage_percentage}% over budget",
            amount: project.current_budget - project.total_budget
          }
        end
        
        # High burn rate alert
        if high_burn_rate?
          alerts << {
            type: 'warning',
            title: 'High Burn Rate',
            message: 'Current spending rate may exhaust budget before completion',
            projected_overrun: calculate_projected_overrun
          }
        end
        
        # Category overruns
        category_overruns = identify_significant_category_overruns
        category_overruns.each do |overrun|
          alerts << {
            type: 'warning',
            title: 'Category Budget Overrun',
            message: "#{overrun[:category]} is #{overrun[:percentage]}% over budget",
            amount: overrun[:amount]
          }
        end
        
        alerts
      end

      def high_burn_rate?
        return false unless project.total_budget && project.end_date && project.start_date
        
        total_months = ((project.end_date - project.start_date) / 30.0).round(1)
        expected_burn_rate = project.total_budget / total_months
        actual_burn_rate = calculate_burn_rate
        
        actual_burn_rate > expected_burn_rate * 1.1
      end

      def calculate_projected_overrun
        forecast = budget_forecast
        projected_total = forecast[:projected_completion_budget]
        
        return nil unless project.total_budget
        
        overrun = projected_total - project.total_budget
        overrun > Money.new(0, 'EUR') ? overrun : nil
      end

      def identify_significant_category_overruns
        overruns = []
        
        costs_by_category.each do |category, costs|
          next if costs[:planned].zero?
          
          variance_percentage = ((costs[:actual] - costs[:planned]).to_f / costs[:planned] * 100).round(2)
          if variance_percentage > 15
            overruns << {
              category: category,
              percentage: variance_percentage,
              amount: costs[:actual] - costs[:planned]
            }
          end
        end
        
        overruns
      end

      def high_variance_suggestions
        suggestions = []
        
        project.budgets.includes(:budget_lines).each do |budget|
          variance = variance_analysis(budget)
          if variance[:status] == 'critical'
            suggestions << {
              type: 'high_variance',
              budget: budget.category,
              variance: variance[:amount],
              recommendation: 'Review and adjust budget allocation or implement cost control measures'
            }
          end
        end
        
        suggestions
      end

      def cost_saving_opportunities
        suggestions = []
        
        # Identify categories with low utilization
        costs_by_category.each do |category, costs|
          utilization = costs[:planned].zero? ? 0 : (costs[:actual].to_f / costs[:planned] * 100)
          if utilization < 50 && costs[:planned] > Money.new(100000, 'EUR')
            suggestions << {
              type: 'underutilized_budget',
              category: category,
              utilization_percentage: utilization.round(2),
              potential_savings: costs[:planned] - costs[:actual],
              recommendation: 'Consider reallocating unused budget to critical areas'
            }
          end
        end
        
        suggestions
      end

      def reallocation_suggestions
        suggestions = []
        
        overruns = identify_cost_overruns
        underutilized = costs_by_category.select do |_, costs|
          costs[:planned] > costs[:actual] + costs[:committed]
        end
        
        if overruns.any? && underutilized.any?
          suggestions << {
            type: 'reallocation_opportunity',
            from: underutilized.keys,
            to: overruns.map { |o| o[:category] }.uniq,
            potential_amount: calculate_reallocation_potential(underutilized),
            recommendation: 'Transfer budget from underutilized categories to overrunning areas'
          }
        end
        
        suggestions
      end

      def calculate_reallocation_potential(underutilized)
        total = underutilized.values.sum do |costs|
          costs[:planned] - costs[:actual] - costs[:committed]
        end
        Money.new(total.cents * 0.5, 'EUR') # Conservative 50% of available
      end

      def calculate_phase_budget(phase)
        # Simplified calculation - would need phase-budget association in real implementation
        total = project.total_budget || Money.new(0, 'EUR')
        phase_count = project.phases.count
        phase_count.zero? ? Money.new(0, 'EUR') : total / phase_count
      end

      def calculate_phase_actual_cost(phase)
        # Simplified - would aggregate from phase-related budget lines
        Money.new(0, 'EUR')
      end

      def calculate_phase_committed_cost(phase)
        # Simplified - would aggregate from phase-related commitments
        Money.new(0, 'EUR')
      end

      def calculate_monthly_cash_flow
        # Simplified monthly cash flow
        monthly_flow = {}
        
        return monthly_flow unless project.start_date
        
        current_date = project.start_date.beginning_of_month
        end_date = Date.current.beginning_of_month
        
        while current_date <= end_date
          month_key = current_date.strftime('%Y-%m')
          monthly_flow[month_key] = {
            inflow: Money.new(0, 'EUR'), # Would include funding, payments
            outflow: calculate_month_spending(current_date),
            net: Money.new(0, 'EUR') # inflow - outflow
          }
          current_date = current_date.next_month
        end
        
        monthly_flow
      end

      def calculate_month_spending(month_date)
        # Simplified - would aggregate actual spending for the month
        calculate_burn_rate
      end

      def calculate_cumulative_spending
        cumulative = []
        total = Money.new(0, 'EUR')
        
        calculate_monthly_cash_flow.each do |month, flow|
          total += flow[:outflow]
          cumulative << {
            month: month,
            amount: total,
            percentage_of_budget: project.total_budget ? (total.to_f / project.total_budget * 100).round(2) : 0
          }
        end
        
        cumulative
      end

      def payment_schedule_summary
        # Would aggregate from contracts and payment milestones
        {
          upcoming_payments: [],
          overdue_payments: [],
          total_outstanding: Money.new(0, 'EUR')
        }
      end

      def calculate_liquidity_needs
        next_3_months = Money.new(0, 'EUR')
        next_6_months = Money.new(0, 'EUR')
        
        # Simplified calculation based on burn rate
        burn_rate = calculate_burn_rate
        next_3_months = burn_rate * 3
        next_6_months = burn_rate * 6
        
        {
          next_3_months: next_3_months,
          next_6_months: next_6_months,
          peak_requirement: [next_3_months, next_6_months, project.remaining_budget].compact.max
        }
      end
    end
  end
end