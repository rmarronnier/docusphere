module Immo
  module Promo
    module FinancialDashboard
      module ProfitabilityTracking
        extend ActiveSupport::Concern

        def profitability_analysis
          @profitability_data = calculate_profitability_metrics
          @margin_analysis = analyze_profit_margins
          @revenue_forecast = forecast_revenue_streams
          @roi_analysis = calculate_roi_metrics
          @value_optimization = identify_value_opportunities
        end

        private

        def calculate_profitability_metrics
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          # Métriques de base
          total_revenue = budget_service.total_projected_revenue
          total_costs = budget_service.total_projected_costs
          gross_profit = total_revenue - total_costs
          
          # Métriques de rentabilité
          {
            gross_profit: gross_profit,
            gross_margin_percent: calculate_gross_margin_percent(gross_profit, total_revenue),
            net_profit: calculate_net_profit(gross_profit),
            net_margin_percent: calculate_net_margin_percent(total_revenue),
            ebitda: calculate_ebitda,
            ebitda_margin: calculate_ebitda_margin(total_revenue),
            operating_profit: calculate_operating_profit,
            operating_margin: calculate_operating_margin(total_revenue),
            contribution_margin: calculate_contribution_margin,
            break_even_point: calculate_break_even_point,
            profitability_ratios: calculate_profitability_ratios
          }
        end

        def analyze_profit_margins
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          # Analyse par phase du projet
          phases_analysis = {}
          @project.phases.each do |phase|
            phases_analysis[phase.name] = analyze_phase_profitability(phase)
          end
          
          # Analyse par type de produit/lot
          products_analysis = {}
          if @project.respond_to?(:lots)
            @project.lots.group_by(&:lot_type).each do |lot_type, lots|
              products_analysis[lot_type] = analyze_product_profitability(lots)
            end
          end
          
          # Benchmarking
          industry_benchmarks = get_industry_benchmarks
          
          {
            overall_margins: calculate_overall_margins,
            phases_breakdown: phases_analysis,
            products_breakdown: products_analysis,
            benchmark_comparison: compare_to_benchmarks(industry_benchmarks),
            margin_trends: analyze_margin_trends,
            optimization_opportunities: identify_margin_optimization_opportunities
          }
        end

        def forecast_revenue_streams
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          # Revenus par source
          revenue_streams = {
            lot_sales: forecast_lot_sales_revenue,
            rental_income: forecast_rental_revenue,
            additional_services: forecast_services_revenue,
            subsidies_grants: forecast_subsidies_revenue
          }
          
          # Prévisions temporelles
          monthly_forecast = {}
          (1..24).each do |month|
            month_key = month.months.from_now.strftime('%Y-%m')
            monthly_forecast[month_key] = forecast_monthly_revenue(month, revenue_streams)
          end
          
          {
            revenue_streams: revenue_streams,
            monthly_forecast: monthly_forecast,
            total_projected: revenue_streams.values.sum,
            revenue_recognition_schedule: create_revenue_recognition_schedule,
            sensitivity_analysis: perform_revenue_sensitivity_analysis(revenue_streams),
            risk_factors: identify_revenue_risk_factors(revenue_streams)
          }
        end

        def calculate_roi_metrics
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          # Données de base
          total_investment = budget_service.total_investment
          projected_returns = budget_service.projected_returns
          project_duration = calculate_project_duration_months
          
          # Calculs ROI
          {
            simple_roi: calculate_simple_roi(projected_returns, total_investment),
            annualized_roi: calculate_annualized_roi(projected_returns, total_investment, project_duration),
            irr: calculate_internal_rate_of_return,
            npv: calculate_net_present_value,
            payback_period: calculate_payback_period,
            profitability_index: calculate_profitability_index,
            modified_irr: calculate_modified_irr,
            roi_sensitivity: perform_roi_sensitivity_analysis,
            comparative_analysis: compare_roi_to_alternatives,
            risk_adjusted_returns: calculate_risk_adjusted_returns
          }
        end

        def identify_value_opportunities
          opportunities = []
          
          # Opportunités de réduction de coûts
          cost_optimization = identify_cost_optimization_opportunities
          opportunities.concat(cost_optimization)
          
          # Opportunités d'augmentation de revenus
          revenue_enhancement = identify_revenue_enhancement_opportunities
          opportunities.concat(revenue_enhancement)
          
          # Opportunités d'optimisation du timing
          timing_optimization = identify_timing_optimization_opportunities
          opportunities.concat(timing_optimization)
          
          # Opportunités fiscales
          tax_optimization = identify_tax_optimization_opportunities
          opportunities.concat(tax_optimization)
          
          # Prioriser et quantifier les opportunités
          prioritized_opportunities = prioritize_opportunities(opportunities)
          
          {
            all_opportunities: opportunities,
            prioritized: prioritized_opportunities,
            quick_wins: prioritized_opportunities.select { |o| o[:implementation_time] < 3 },
            high_impact: prioritized_opportunities.select { |o| o[:value_impact] > 100000 },
            implementation_roadmap: create_implementation_roadmap(prioritized_opportunities)
          }
        end

        # Méthodes de calcul spécialisées

        def calculate_gross_margin_percent(gross_profit, total_revenue)
          return 0 if total_revenue.zero?
          (gross_profit / total_revenue.to_f * 100).round(2)
        end

        def calculate_net_profit(gross_profit)
          # Soustraire les coûts indirects, taxes, etc.
          indirect_costs = calculate_indirect_costs
          taxes = calculate_estimated_taxes(gross_profit - indirect_costs)
          
          gross_profit - indirect_costs - taxes
        end

        def calculate_ebitda
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          operating_income = budget_service.operating_income
          depreciation = budget_service.depreciation_expenses
          amortization = budget_service.amortization_expenses
          
          operating_income + depreciation + amortization
        end

        def calculate_break_even_point
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          fixed_costs = budget_service.fixed_costs
          variable_cost_ratio = budget_service.variable_cost_ratio
          average_selling_price = budget_service.average_selling_price
          
          # Point mort en unités
          contribution_margin_per_unit = average_selling_price * (1 - variable_cost_ratio)
          break_even_units = fixed_costs / contribution_margin_per_unit
          
          # Point mort en valeur
          break_even_revenue = break_even_units * average_selling_price
          
          {
            units: break_even_units.round,
            revenue: break_even_revenue.round,
            timeline: estimate_break_even_timeline(break_even_revenue),
            margin_of_safety: calculate_margin_of_safety(break_even_revenue)
          }
        end

        def calculate_internal_rate_of_return
          cash_flows = build_project_cash_flows
          
          # Calcul IRR par approximation (méthode de Newton-Raphson simplifiée)
          irr = 0.1 # Estimation initiale à 10%
          tolerance = 0.0001
          max_iterations = 100
          
          max_iterations.times do |i|
            npv = calculate_npv_at_rate(cash_flows, irr)
            npv_derivative = calculate_npv_derivative(cash_flows, irr)
            
            break if npv_derivative.abs < tolerance
            
            new_irr = irr - (npv / npv_derivative)
            break if (new_irr - irr).abs < tolerance
            
            irr = new_irr
          end
          
          (irr * 100).round(2) # Retourner en pourcentage
        end

        def forecast_lot_sales_revenue
          return 0 unless @project.respond_to?(:lots)
          
          total_revenue = 0
          @project.lots.each do |lot|
            sale_probability = calculate_lot_sale_probability(lot)
            expected_price = calculate_expected_lot_price(lot)
            expected_timing = estimate_sale_timing(lot)
            
            total_revenue += sale_probability * expected_price
          end
          
          total_revenue
        end

        def identify_cost_optimization_opportunities
          opportunities = []
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          # Analyse des coûts par catégorie
          cost_categories = budget_service.cost_breakdown_by_category
          
          cost_categories.each do |category, amount|
            # Identifier les opportunités d'optimisation par catégorie
            category_opportunities = analyze_category_optimization(category, amount)
            opportunities.concat(category_opportunities)
          end
          
          opportunities
        end

        def identify_revenue_enhancement_opportunities
          opportunities = []
          
          # Opportunités de montée en gamme
          premium_opportunities = identify_premium_opportunities
          opportunities.concat(premium_opportunities)
          
          # Services additionnels
          additional_services = identify_additional_services_opportunities
          opportunities.concat(additional_services)
          
          # Optimisation pricing
          pricing_opportunities = identify_pricing_optimization_opportunities
          opportunities.concat(pricing_opportunities)
          
          opportunities
        end

        def prioritize_opportunities(opportunities)
          # Scorer chaque opportunité sur plusieurs critères
          scored_opportunities = opportunities.map do |opportunity|
            score = calculate_opportunity_score(opportunity)
            opportunity.merge(priority_score: score)
          end
          
          # Trier par score décroissant
          scored_opportunities.sort_by { |o| o[:priority_score] }.reverse
        end

        def calculate_opportunity_score(opportunity)
          # Critères de scoring (pondérés)
          value_score = normalize_value_impact(opportunity[:value_impact]) * 0.4
          feasibility_score = opportunity[:feasibility_score] * 0.3
          time_score = normalize_implementation_time(opportunity[:implementation_time]) * 0.2
          risk_score = (1 - opportunity[:risk_level]) * 0.1
          
          value_score + feasibility_score + time_score + risk_score
        end

        # Méthodes utilitaires

        def build_project_cash_flows
          # Construire le tableau des flux de trésorerie du projet
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          cash_flows = []
          project_months = calculate_project_duration_months
          
          # Investissement initial (flux négatif)
          cash_flows << -budget_service.initial_investment
          
          # Flux mensuels du projet
          (1..project_months).each do |month|
            monthly_cash_flow = budget_service.projected_monthly_cash_flow(month)
            cash_flows << monthly_cash_flow
          end
          
          cash_flows
        end

        def calculate_npv_at_rate(cash_flows, rate)
          npv = 0
          cash_flows.each_with_index do |cash_flow, period|
            npv += cash_flow / ((1 + rate) ** period)
          end
          npv
        end

        def normalize_value_impact(value)
          # Normaliser la valeur entre 0 et 1
          max_value = 1000000 # Valeur de référence maximum
          [value / max_value.to_f, 1.0].min
        end

        def normalize_implementation_time(time_months)
          # Score inversé : moins de temps = meilleur score
          max_time = 24 # 24 mois maximum
          [1 - (time_months / max_time.to_f), 0].max
        end
      end
    end
  end
end