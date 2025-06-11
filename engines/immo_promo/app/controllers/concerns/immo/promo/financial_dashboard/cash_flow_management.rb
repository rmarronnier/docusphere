module Immo
  module Promo
    module FinancialDashboard
      module CashFlowManagement
        extend ActiveSupport::Concern

        def cash_flow_management
          @budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          @cash_flow = @budget_service.cash_flow_analysis
          @liquidity_forecast = forecast_liquidity_needs
          @payment_schedule = optimize_payment_schedule
          @financing_recommendations = assess_financing_needs
        end

        private

        def forecast_liquidity_needs
          cash_flow_data = @budget_service.cash_flow_analysis
          
          # Prévision sur 12 mois
          forecast = {}
          (1..12).each do |month|
            month_key = month.months.from_now.strftime('%Y-%m')
            forecast[month_key] = calculate_monthly_liquidity_needs(month, cash_flow_data)
          end

          {
            monthly_forecast: forecast,
            critical_periods: identify_critical_liquidity_periods(forecast),
            minimum_cash_requirement: calculate_minimum_cash_requirement(forecast),
            liquidity_buffer_recommendation: recommend_liquidity_buffer(forecast)
          }
        end

        def optimize_payment_schedule
          payments = @project.payment_schedule || []
          cash_position = @budget_service.current_cash_position
          
          optimized_schedule = []
          cumulative_cash = cash_position

          payments.sort_by { |p| p[:due_date] }.each do |payment|
            optimized_payment = optimize_individual_payment(payment, cumulative_cash)
            optimized_schedule << optimized_payment
            cumulative_cash += optimized_payment[:cash_impact]
          end

          {
            original_schedule: payments,
            optimized_schedule: optimized_schedule,
            cash_savings: calculate_cash_savings(payments, optimized_schedule),
            risk_assessment: assess_payment_schedule_risks(optimized_schedule)
          }
        end

        def assess_financing_needs
          liquidity_forecast = forecast_liquidity_needs
          current_financing = @budget_service.current_financing_structure
          
          financing_gaps = identify_financing_gaps(liquidity_forecast)
          
          recommendations = []
          
          financing_gaps.each do |gap|
            recommendations << generate_financing_recommendation(gap, current_financing)
          end

          {
            current_structure: current_financing,
            identified_gaps: financing_gaps,
            recommendations: recommendations,
            optimal_structure: design_optimal_financing_structure(recommendations)
          }
        end

        def calculate_monthly_liquidity_needs(month, cash_flow_data)
          base_date = month.months.from_now.beginning_of_month
          
          # Recettes prévues
          expected_inflows = calculate_expected_inflows(base_date)
          
          # Dépenses prévues
          expected_outflows = calculate_expected_outflows(base_date)
          
          # Obligations contractuelles
          contractual_obligations = calculate_contractual_obligations(base_date)
          
          net_cash_flow = expected_inflows - expected_outflows - contractual_obligations
          
          {
            period: base_date.strftime('%Y-%m'),
            expected_inflows: expected_inflows,
            expected_outflows: expected_outflows,
            contractual_obligations: contractual_obligations,
            net_cash_flow: net_cash_flow,
            cumulative_position: calculate_cumulative_position(base_date, net_cash_flow),
            liquidity_status: assess_monthly_liquidity_status(net_cash_flow)
          }
        end

        def identify_critical_liquidity_periods(forecast)
          critical_periods = []
          
          forecast.each do |period, data|
            if data[:net_cash_flow] < 0 || data[:cumulative_position] < minimum_cash_threshold
              critical_periods << {
                period: period,
                severity: calculate_liquidity_severity(data),
                required_action: determine_required_liquidity_action(data),
                timeline: calculate_action_timeline(data)
              }
            end
          end

          critical_periods.sort_by { |p| p[:severity] }.reverse
        end

        def optimize_individual_payment(payment, current_cash)
          original_amount = payment[:amount]
          due_date = payment[:due_date]
          
          # Vérifier si le paiement peut être optimisé
          optimization_options = []
          
          # Option 1: Paiement anticipé avec remise
          if current_cash > original_amount * 1.2
            early_payment_option = calculate_early_payment_option(payment)
            optimization_options << early_payment_option if early_payment_option[:beneficial]
          end
          
          # Option 2: Étalement du paiement
          if original_amount > 50000 # Seuil pour l'étalement
            split_payment_option = calculate_split_payment_option(payment)
            optimization_options << split_payment_option if split_payment_option[:beneficial]
          end
          
          # Option 3: Report avec pénalités
          if current_cash < original_amount
            delayed_payment_option = calculate_delayed_payment_option(payment)
            optimization_options << delayed_payment_option
          end

          # Sélectionner la meilleure option
          best_option = select_best_payment_option(payment, optimization_options)
          
          payment.merge(
            optimization_applied: best_option,
            cash_impact: calculate_payment_cash_impact(payment, best_option),
            rationale: generate_optimization_rationale(best_option)
          )
        end

        def identify_financing_gaps(liquidity_forecast)
          gaps = []
          
          liquidity_forecast[:monthly_forecast].each do |period, data|
            if data[:cumulative_position] < 0
              gap_amount = data[:cumulative_position].abs
              
              gaps << {
                period: period,
                amount: gap_amount,
                duration: estimate_gap_duration(period, liquidity_forecast),
                urgency: calculate_gap_urgency(data),
                recommended_instruments: recommend_financing_instruments(gap_amount, data)
              }
            end
          end

          gaps
        end

        def generate_financing_recommendation(gap, current_structure)
          {
            gap_details: gap,
            recommended_instrument: select_optimal_financing_instrument(gap, current_structure),
            terms_suggestion: suggest_financing_terms(gap),
            impact_analysis: analyze_financing_impact(gap, current_structure),
            implementation_timeline: estimate_implementation_timeline(gap),
            alternative_options: identify_alternative_financing_options(gap)
          }
        end

        def design_optimal_financing_structure(recommendations)
          # Consolider toutes les recommandations en une structure optimale
          total_financing_need = recommendations.sum { |r| r[:gap_details][:amount] }
          
          optimal_structure = {
            short_term_facilities: design_short_term_facilities(recommendations),
            medium_term_loans: design_medium_term_loans(recommendations),
            equity_requirements: calculate_equity_requirements(total_financing_need),
            contingency_facilities: design_contingency_facilities(recommendations)
          }

          # Calculer les coûts et bénéfices
          optimal_structure.merge(
            total_cost: calculate_total_financing_cost(optimal_structure),
            implementation_plan: create_implementation_plan(optimal_structure),
            risk_mitigation: identify_financing_risk_mitigation(optimal_structure)
          )
        end

        def calculate_expected_inflows(base_date)
          # Ventes prévues
          sales_forecast = @budget_service.sales_forecast_for_month(base_date)
          
          # Autres recettes (subventions, etc.)
          other_inflows = @budget_service.other_inflows_for_month(base_date)
          
          sales_forecast + other_inflows
        end

        def calculate_expected_outflows(base_date)
          # Coûts de construction
          construction_costs = @budget_service.construction_costs_for_month(base_date)
          
          # Coûts opérationnels
          operational_costs = @budget_service.operational_costs_for_month(base_date)
          
          # Marketing et ventes
          sales_costs = @budget_service.sales_costs_for_month(base_date)
          
          construction_costs + operational_costs + sales_costs
        end

        def select_optimal_financing_instrument(gap, current_structure)
          instruments = %w[credit_line term_loan bridge_loan equity_injection]
          scores = {}

          instruments.each do |instrument|
            scores[instrument] = evaluate_financing_instrument(instrument, gap, current_structure)
          end

          # Retourner l'instrument avec le meilleur score
          best_instrument = scores.max_by { |_, score| score }.first
          
          {
            instrument: best_instrument,
            score: scores[best_instrument],
            rationale: generate_instrument_selection_rationale(best_instrument, gap)
          }
        end

        def evaluate_financing_instrument(instrument, gap, current_structure)
          score = 0
          
          # Critères d'évaluation
          score += evaluate_cost_efficiency(instrument, gap)
          score += evaluate_flexibility(instrument, gap)
          score += evaluate_speed_of_access(instrument, gap)
          score += evaluate_structure_compatibility(instrument, current_structure)
          score += evaluate_risk_profile(instrument, gap)
          
          score
        end

        # Méthodes utilitaires pour l'évaluation

        def minimum_cash_threshold
          @budget_service.calculate_minimum_cash_threshold
        end

        def calculate_liquidity_severity(data)
          deficit_ratio = data[:cumulative_position].abs / @budget_service.monthly_average_outflow
          [deficit_ratio / 3.0, 1.0].min # Normaliser entre 0 et 1
        end

        def evaluate_cost_efficiency(instrument, gap)
          # Logique d'évaluation du coût
          case instrument
          when 'credit_line'
            gap[:amount] < 1000000 ? 30 : 20
          when 'term_loan'
            gap[:duration] > 6 ? 25 : 15
          when 'bridge_loan'
            gap[:urgency] > 0.7 ? 20 : 10
          when 'equity_injection'
            gap[:amount] > 2000000 ? 35 : 25
          else
            10
          end
        end
      end
    end
  end
end