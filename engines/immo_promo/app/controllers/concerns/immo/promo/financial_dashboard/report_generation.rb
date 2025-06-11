module Immo
  module Promo
    module FinancialDashboard
      module ReportGeneration
        extend ActiveSupport::Concern

        def generate_financial_report
          @budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          @report_data = compile_comprehensive_financial_report
          
          respond_to do |format|
            format.pdf do
              render pdf: "rapport_financier_#{@project.reference_number}",
                     layout: 'pdf',
                     template: 'immo/promo/financial_dashboard/comprehensive_report_pdf'
            end
            format.xlsx do
              render xlsx: 'financial_report_xlsx',
                     filename: "rapport_financier_#{@project.reference_number}.xlsx"
            end
          end
        end

        def export_budget_data
          format = params[:format] || 'csv'
          @budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          case format
          when 'csv'
            csv_data = generate_budget_csv
            send_data csv_data, filename: "budget_#{@project.reference_number}.csv", type: 'text/csv'
          when 'json'
            json_data = @budget_service.budget_summary.to_json
            send_data json_data, filename: "budget_#{@project.reference_number}.json", type: 'application/json'
          else
            flash[:error] = "Format d'export non supporté"
            redirect_back(fallback_location: immo_promo_engine.project_financial_dashboard_path(@project))
          end
        end

        def sync_accounting_system
          # Intégration avec système comptable externe
          sync_result = synchronize_with_accounting
          
          if sync_result[:success]
            flash[:success] = "Synchronisation comptable réussie"
            flash[:info] = "#{sync_result[:updated_records]} enregistrements mis à jour"
          else
            flash[:error] = "Erreur de synchronisation : #{sync_result[:error]}"
          end
          
          redirect_to immo_promo_engine.project_financial_dashboard_path(@project)
        end

        private

        def compile_comprehensive_financial_report
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          
          {
            executive_summary: generate_executive_summary(budget_service),
            financial_overview: generate_financial_overview(budget_service),
            budget_analysis: generate_budget_analysis_section(budget_service),
            profitability_analysis: generate_profitability_section(budget_service),
            cash_flow_analysis: generate_cash_flow_section(budget_service),
            risk_assessment: generate_risk_assessment_section(budget_service),
            recommendations: generate_recommendations_section(budget_service),
            appendices: generate_appendices(budget_service),
            metadata: generate_report_metadata
          }
        end

        def generate_executive_summary(budget_service)
          summary = budget_service.budget_summary
          
          {
            project_overview: {
              name: @project.name,
              reference: @project.reference_number,
              type: @project.project_type,
              status: @project.status,
              start_date: @project.start_date,
              expected_completion: @project.expected_completion_date
            },
            key_financial_metrics: {
              total_budget: summary[:total_budget],
              spent_to_date: summary[:spent_amount],
              remaining_budget: summary[:remaining_budget],
              budget_utilization: summary[:utilization_percentage],
              projected_final_cost: budget_service.projected_final_cost,
              variance_to_budget: calculate_variance_to_budget(budget_service)
            },
            profitability_snapshot: {
              projected_revenue: budget_service.total_projected_revenue,
              projected_profit: budget_service.projected_profit,
              profit_margin: budget_service.profit_margin_percentage,
              roi: budget_service.return_on_investment
            },
            critical_alerts: identify_critical_financial_alerts(budget_service),
            next_milestones: identify_next_financial_milestones
          }
        end

        def generate_financial_overview(budget_service)
          {
            budget_breakdown: budget_service.detailed_budget_breakdown,
            cost_categories: budget_service.cost_breakdown_by_category,
            spending_timeline: budget_service.spending_timeline,
            budget_vs_actual: budget_service.budget_vs_actual_analysis,
            forecast_accuracy: assess_forecast_accuracy(budget_service),
            financial_ratios: calculate_key_financial_ratios(budget_service)
          }
        end

        def generate_budget_analysis_section(budget_service)
          {
            variance_analysis: budget_service.variance_analysis,
            category_performance: analyze_category_performance(budget_service),
            trend_analysis: analyze_spending_trends(budget_service),
            efficiency_metrics: calculate_efficiency_metrics(budget_service),
            optimization_opportunities: identify_budget_optimization_opportunities(budget_service)
          }
        end

        def generate_profitability_section(budget_service)
          {
            revenue_analysis: analyze_revenue_streams(budget_service),
            cost_structure: analyze_cost_structure(budget_service),
            margin_analysis: analyze_profit_margins(budget_service),
            break_even_analysis: calculate_break_even_analysis(budget_service),
            sensitivity_analysis: perform_profitability_sensitivity_analysis(budget_service),
            benchmarking: compare_to_industry_benchmarks(budget_service)
          }
        end

        def generate_cash_flow_section(budget_service)
          {
            current_position: budget_service.current_cash_position,
            cash_flow_forecast: budget_service.cash_flow_forecast,
            liquidity_analysis: analyze_liquidity_position(budget_service),
            funding_requirements: assess_funding_requirements(budget_service),
            payment_schedule_optimization: optimize_payment_schedules(budget_service)
          }
        end

        def generate_risk_assessment_section(budget_service)
          {
            financial_risks: identify_financial_risks(budget_service),
            risk_impact_analysis: assess_risk_impacts(budget_service),
            mitigation_strategies: develop_risk_mitigation_strategies(budget_service),
            contingency_planning: develop_financial_contingency_plans(budget_service),
            monte_carlo_analysis: perform_monte_carlo_simulation(budget_service)
          }
        end

        def generate_recommendations_section(budget_service)
          recommendations = []
          
          # Recommandations basées sur l'analyse des variances
          variance_recommendations = generate_variance_based_recommendations(budget_service)
          recommendations.concat(variance_recommendations)
          
          # Recommandations d'optimisation
          optimization_recommendations = generate_optimization_recommendations(budget_service)
          recommendations.concat(optimization_recommendations)
          
          # Recommandations de financement
          financing_recommendations = generate_financing_recommendations(budget_service)
          recommendations.concat(financing_recommendations)
          
          # Prioriser et structurer les recommandations
          {
            high_priority: recommendations.select { |r| r[:priority] == 'high' },
            medium_priority: recommendations.select { |r| r[:priority] == 'medium' },
            low_priority: recommendations.select { |r| r[:priority] == 'low' },
            implementation_roadmap: create_recommendations_roadmap(recommendations)
          }
        end

        def generate_budget_csv
          require 'csv'
          
          budget_service = Immo::Promo::ProjectBudgetService.new(@project)
          budget_data = budget_service.detailed_budget_breakdown
          
          CSV.generate(headers: true) do |csv|
            # En-têtes
            csv << [
              'Catégorie',
              'Sous-catégorie',
              'Description',
              'Budget initial',
              'Budget révisé',
              'Dépensé',
              'Engagé',
              'Disponible',
              'Variance',
              'Variance %',
              'Statut'
            ]
            
            # Données
            budget_data.each do |category_data|
              category_data[:lines].each do |line|
                csv << [
                  category_data[:category],
                  line[:subcategory],
                  line[:description],
                  line[:initial_budget],
                  line[:revised_budget],
                  line[:spent_amount],
                  line[:committed_amount],
                  line[:available_amount],
                  line[:variance],
                  line[:variance_percentage],
                  line[:status]
                ]
              end
            end
          end
        end

        def synchronize_with_accounting
          # Simulation d'une synchronisation avec un système comptable
          begin
            sync_service = AccountingSyncService.new(@project)
            
            # Récupérer les données du système comptable
            accounting_data = sync_service.fetch_accounting_data
            
            # Synchroniser les transactions
            updated_count = sync_service.update_project_transactions(accounting_data)
            
            # Mettre à jour les budgets
            sync_service.reconcile_budget_data
            
            # Générer un rapport de synchronisation
            sync_report = sync_service.generate_sync_report
            
            {
              success: true,
              updated_records: updated_count,
              sync_report: sync_report,
              last_sync: Time.current
            }
          rescue StandardError => e
            Rails.logger.error "Erreur de synchronisation comptable: #{e.message}"
            {
              success: false,
              error: e.message,
              last_sync: @project.last_accounting_sync
            }
          end
        end

        # Méthodes utilitaires pour la génération de rapports

        def calculate_variance_to_budget(budget_service)
          summary = budget_service.budget_summary
          total_budget = summary[:total_budget]
          projected_final = budget_service.projected_final_cost
          
          variance = projected_final - total_budget
          variance_percent = total_budget.zero? ? 0 : (variance / total_budget.to_f * 100)
          
          {
            absolute_variance: variance,
            percentage_variance: variance_percent.round(2),
            status: variance_percent > 10 ? 'critical' : variance_percent > 5 ? 'warning' : 'acceptable'
          }
        end

        def identify_critical_financial_alerts(budget_service)
          alerts = []
          
          # Alerte dépassement budgétaire
          variance = calculate_variance_to_budget(budget_service)
          if variance[:percentage_variance] > 10
            alerts << {
              type: 'budget_overrun',
              severity: 'critical',
              message: "Dépassement budgétaire de #{variance[:percentage_variance]}%",
              recommended_action: 'Révision immédiate du budget requise'
            }
          end
          
          # Alerte liquidité
          cash_position = budget_service.current_cash_position
          if cash_position[:days_of_runway] < 30
            alerts << {
              type: 'liquidity_risk',
              severity: 'high',
              message: "Liquidité critique - #{cash_position[:days_of_runway]} jours restants",
              recommended_action: 'Sécuriser un financement immédiatement'
            }
          end
          
          alerts
        end

        def assess_forecast_accuracy(budget_service)
          historical_forecasts = budget_service.historical_forecasts
          actual_spending = budget_service.actual_spending_timeline
          
          accuracy_scores = []
          
          historical_forecasts.each do |forecast|
            period_actual = actual_spending[forecast[:period]]
            if period_actual
              accuracy = calculate_forecast_accuracy(forecast[:amount], period_actual)
              accuracy_scores << accuracy
            end
          end
          
          average_accuracy = accuracy_scores.empty? ? 0 : accuracy_scores.sum / accuracy_scores.length
          
          {
            average_accuracy: average_accuracy.round(2),
            accuracy_trend: calculate_accuracy_trend(accuracy_scores),
            reliability_score: assess_forecast_reliability(accuracy_scores)
          }
        end

        def perform_monte_carlo_simulation(budget_service)
          # Simulation Monte Carlo simplifiée pour l'analyse de risque
          iterations = 1000
          results = []
          
          iterations.times do
            # Générer des scénarios aléatoires basés sur les distributions historiques
            scenario_costs = simulate_scenario_costs(budget_service)
            scenario_revenue = simulate_scenario_revenue(budget_service)
            scenario_profit = scenario_revenue - scenario_costs
            
            results << {
              costs: scenario_costs,
              revenue: scenario_revenue,
              profit: scenario_profit
            }
          end
          
          # Analyser les résultats
          {
            profit_distribution: analyze_profit_distribution(results),
            risk_metrics: calculate_risk_metrics(results),
            confidence_intervals: calculate_confidence_intervals(results),
            worst_case_scenarios: identify_worst_case_scenarios(results),
            best_case_scenarios: identify_best_case_scenarios(results)
          }
        end

        def generate_report_metadata
          {
            generated_at: Time.current,
            generated_by: current_user.name,
            report_version: '1.0',
            data_as_of: @project.last_financial_update || Time.current,
            currency: 'EUR',
            disclaimer: 'Ce rapport est basé sur les données disponibles à la date de génération.',
            next_update_due: calculate_next_update_date
          }
        end

        def calculate_next_update_date
          # Calculer la prochaine date de mise à jour recommandée
          case @project.status
          when 'planning'
            1.month.from_now
          when 'construction'
            2.weeks.from_now
          when 'completion'
            3.months.from_now
          else
            1.month.from_now
          end
        end
      end
    end
  end
end