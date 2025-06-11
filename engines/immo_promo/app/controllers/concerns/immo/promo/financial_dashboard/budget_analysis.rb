module Immo
  module Promo
    module FinancialDashboard
      module BudgetAnalysis
        extend ActiveSupport::Concern

        def variance_analysis
          @budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          @variance_data = detailed_variance_analysis
          @trends = analyze_variance_trends
          @category_performance = analyze_category_performance
          @recommendations = generate_variance_recommendations
        end

        def cost_control
          @budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          @cost_tracking = @budget_service.cost_tracking_report
          @overruns = @cost_tracking[:cost_overruns]
          @top_expenses = @cost_tracking[:top_expenses]
          @cost_trends = analyze_cost_trends
          @control_measures = suggest_cost_control_measures
        end

        def budget_scenarios
          @budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          @base_forecast = @budget_service.budget_forecast
          @scenarios = generate_detailed_scenarios
          @risk_assessment = assess_budget_risks
          @contingency_plans = develop_contingency_plans
        end

        private

        def detailed_variance_analysis
          @budget_service.detailed_budget_breakdown.map do |budget_data|
            budget_data.merge(
              detailed_variances: analyze_budget_line_variances(budget_data[:lines]),
              variance_drivers: identify_variance_drivers(budget_data[:variance_analysis]),
              corrective_actions: suggest_corrective_actions(budget_data[:variance_analysis])
            )
          end
        end

        def analyze_budget_line_variances(budget_lines)
          budget_lines.map do |line|
            planned = line[:planned_amount]
            actual = line[:actual_amount]
            variance = actual - planned
            variance_percent = planned.zero? ? 0 : (variance / planned.to_f * 100).round(2)
            
            line.merge(
              variance: variance,
              variance_percent: variance_percent,
              variance_category: categorize_variance(variance_percent),
              explanation: explain_variance(line, variance_percent),
              impact_assessment: assess_variance_impact(line, variance_percent)
            )
          end
        end

        def analyze_variance_trends
          # Analyse des tendances de variance sur plusieurs périodes
          periods = get_reporting_periods
          trends = {}

          periods.each do |period|
            period_data = @budget_service.budget_summary_for_period(period)
            trends[period] = calculate_period_variances(period_data)
          end

          {
            trend_direction: determine_trend_direction(trends),
            seasonality: detect_seasonality_patterns(trends),
            predictive_indicators: extract_predictive_indicators(trends)
          }
        end

        def analyze_category_performance
          categories = @budget_service.budget_categories
          performance_data = {}

          categories.each do |category|
            category_budget = @budget_service.category_budget_analysis(category)
            performance_data[category] = {
              efficiency_score: calculate_efficiency_score(category_budget),
              reliability_score: calculate_reliability_score(category_budget),
              optimization_potential: assess_optimization_potential(category_budget),
              benchmark_comparison: compare_to_benchmarks(category, category_budget)
            }
          end

          performance_data
        end

        def generate_variance_recommendations
          variance_data = detailed_variance_analysis
          recommendations = []

          variance_data.each do |budget|
            budget[:detailed_variances].each do |line|
              if line[:variance_percent].abs > 10 # Variance significative
                recommendations << generate_line_recommendation(line)
              end
            end
          end

          # Grouper et prioriser les recommandations
          prioritize_recommendations(recommendations)
        end

        def analyze_cost_trends
          cost_data = @budget_service.historical_cost_data
          
          {
            monthly_trends: calculate_monthly_cost_trends(cost_data),
            category_trends: calculate_category_cost_trends(cost_data),
            inflation_impact: assess_inflation_impact(cost_data),
            seasonal_patterns: identify_seasonal_cost_patterns(cost_data)
          }
        end

        def suggest_cost_control_measures
          cost_analysis = @cost_tracking
          measures = []

          # Mesures basées sur les dépassements
          if cost_analysis[:total_overrun_percent] > 5
            measures << {
              priority: 'high',
              category: 'immediate_action',
              action: 'Gel des dépenses non-critiques',
              expected_savings: estimate_freeze_savings,
              implementation_time: '1 semaine'
            }
          end

          # Mesures basées sur les tendances
          if cost_analysis[:trend] == 'increasing'
            measures << {
              priority: 'medium',
              category: 'process_improvement',
              action: 'Révision des processus d\'approvisionnement',
              expected_savings: estimate_process_savings,
              implementation_time: '1 mois'
            }
          end

          measures
        end

        def generate_detailed_scenarios
          base_budget = @budget_service.budget_summary
          
          {
            optimistic: generate_optimistic_scenario(base_budget),
            pessimistic: generate_pessimistic_scenario(base_budget),
            most_likely: generate_most_likely_scenario(base_budget),
            stress_test: generate_stress_test_scenario(base_budget)
          }
        end

        def assess_budget_risks
          risks = []
          
          # Risques de dépassement
          overrun_probability = calculate_overrun_probability
          if overrun_probability > 0.3
            risks << {
              type: 'cost_overrun',
              probability: overrun_probability,
              impact: 'high',
              mitigation: 'Renforcer le contrôle des dépenses'
            }
          end

          # Risques de liquidité
          liquidity_risk = assess_liquidity_risk
          if liquidity_risk[:severity] > 0.5
            risks << {
              type: 'liquidity',
              probability: liquidity_risk[:probability],
              impact: 'critical',
              mitigation: 'Négocier un financement pont'
            }
          end

          risks
        end

        def develop_contingency_plans
          risks = assess_budget_risks
          plans = {}

          risks.each do |risk|
            plans[risk[:type]] = {
              trigger_conditions: define_trigger_conditions(risk),
              response_actions: define_response_actions(risk),
              responsible_parties: assign_responsible_parties(risk),
              monitoring_metrics: define_monitoring_metrics(risk)
            }
          end

          plans
        end

        # Méthodes utilitaires privées

        def categorize_variance(variance_percent)
          case variance_percent.abs
          when 0..5
            'acceptable'
          when 5..15
            'concerning'
          when 15..25
            'significant'
          else
            'critical'
          end
        end

        def explain_variance(line, variance_percent)
          # Logique d'explication basée sur le type de ligne budgétaire et l'historique
          if variance_percent > 0
            "Dépassement de #{variance_percent.abs}% sur #{line[:description]}"
          else
            "Économie de #{variance_percent.abs}% sur #{line[:description]}"
          end
        end

        def calculate_overrun_probability
          # Calcul basé sur l'historique et les tendances actuelles
          historical_overruns = @budget_service.historical_overrun_rate
          current_variance_trend = @budget_service.current_variance_trend
          
          base_probability = historical_overruns
          trend_adjustment = current_variance_trend * 0.3
          
          [base_probability + trend_adjustment, 1.0].min
        end

        def assess_liquidity_risk
          cash_flow = @budget_service.cash_flow_analysis
          
          {
            severity: calculate_liquidity_severity(cash_flow),
            probability: calculate_liquidity_probability(cash_flow),
            timeline: estimate_liquidity_timeline(cash_flow)
          }
        end
      end
    end
  end
end