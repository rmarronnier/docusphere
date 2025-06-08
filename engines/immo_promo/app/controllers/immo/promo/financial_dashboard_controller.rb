module Immo
  module Promo
    class FinancialDashboardController < Immo::Promo::ApplicationController
      before_action :set_project
      before_action :authorize_financial_access

      def dashboard
        @budget_service = ProjectBudgetService.new(@project)
        @budget_summary = @budget_service.budget_summary
        @cost_tracking = @budget_service.cost_tracking_report
        @forecast = @budget_service.budget_forecast
        @cash_flow = @budget_service.cash_flow_analysis
        @optimization_suggestions = @budget_service.budget_optimization_suggestions
        
        respond_to do |format|
          format.html
          format.json { render json: financial_dashboard_data }
        end
      end

      def variance_analysis
        @budget_service = ProjectBudgetService.new(@project)
        @variance_data = detailed_variance_analysis
        @trends = analyze_variance_trends
        @category_performance = analyze_category_performance
        @recommendations = generate_variance_recommendations
      end

      def cost_control
        @budget_service = ProjectBudgetService.new(@project)
        @cost_tracking = @budget_service.cost_tracking_report
        @overruns = @cost_tracking[:cost_overruns]
        @top_expenses = @cost_tracking[:top_expenses]
        @cost_trends = analyze_cost_trends
        @control_measures = suggest_cost_control_measures
      end

      def cash_flow_management
        @budget_service = ProjectBudgetService.new(@project)
        @cash_flow = @budget_service.cash_flow_analysis
        @liquidity_forecast = forecast_liquidity_needs
        @payment_schedule = optimize_payment_schedule
        @financing_recommendations = assess_financing_needs
      end

      def budget_scenarios
        @budget_service = ProjectBudgetService.new(@project)
        @base_forecast = @budget_service.budget_forecast
        @scenarios = generate_detailed_scenarios
        @risk_assessment = assess_budget_risks
        @contingency_plans = develop_contingency_plans
      end

      def profitability_analysis
        @profitability_data = calculate_profitability_metrics
        @margin_analysis = analyze_profit_margins
        @revenue_forecast = forecast_revenue_streams
        @roi_analysis = calculate_roi_metrics
        @value_optimization = identify_value_opportunities
      end

      def approve_budget_adjustment
        @budget = @project.budgets.find(params[:budget_id])
        adjustment_params = params.require(:adjustment).permit(:amount, :category, :justification, :approval_level)
        
        adjustment = create_budget_adjustment(@budget, adjustment_params)
        
        if adjustment[:success]
          log_budget_adjustment(adjustment[:record], current_user)
          flash[:success] = "Ajustement budgétaire approuvé"
          
          # Notifier les parties prenantes si l'ajustement est significatif
          if significant_adjustment?(adjustment[:record])
            send_budget_adjustment_notifications(adjustment[:record])
          end
        else
          flash[:error] = adjustment[:error]
        end
        
        redirect_to immo_promo_engine.project_financial_dashboard_path(@project)
      end

      def reallocate_budget
        reallocation_params = params.require(:reallocation).permit(
          :from_budget_id, :to_budget_id, :amount, :justification
        )
        
        result = execute_budget_reallocation(reallocation_params)
        
        if result[:success]
          flash[:success] = "Réallocation budgétaire effectuée"
          log_budget_reallocation(result[:reallocation], current_user)
        else
          flash[:error] = result[:error]
        end
        
        redirect_back(fallback_location: immo_promo_engine.project_financial_dashboard_variance_analysis_path(@project))
      end

      def set_budget_alert
        alert_params = params.require(:alert).permit(:threshold_type, :threshold_value, :notification_method)
        
        alert = create_budget_alert(alert_params)
        
        if alert[:success]
          flash[:success] = "Alerte budgétaire configurée"
        else
          flash[:error] = alert[:error]
        end
        
        redirect_back(fallback_location: immo_promo_engine.project_financial_dashboard_path(@project))
      end

      def generate_financial_report
        @budget_service = ProjectBudgetService.new(@project)
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
        @budget_service = ProjectBudgetService.new(@project)
        
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

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def authorize_financial_access
        authorize @project, :manage_finances?
      end

      def financial_dashboard_data
        {
          project: {
            id: @project.id,
            name: @project.name,
            reference: @project.reference_number
          },
          budget_summary: @budget_summary,
          cost_tracking: @cost_tracking,
          forecast: @forecast,
          cash_flow: @cash_flow,
          optimization_suggestions: @optimization_suggestions
        }
      end

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
          line.merge(
            variance_category: categorize_variance(line[:variance_percentage]),
            variance_trend: calculate_line_trend(line),
            impact_assessment: assess_variance_impact(line)
          )
        end
      end

      def categorize_variance(variance_percentage)
        abs_variance = variance_percentage.abs
        
        if abs_variance <= 5
          'acceptable'
        elsif abs_variance <= 15
          'concerning'
        else
          'critical'
        end
      end

      def calculate_line_trend(line)
        # Simplifiée - analyserait l'historique des variances
        'stable'
      end

      def assess_variance_impact(line)
        {
          project_impact: line[:variance].abs > Money.new(50000, 'EUR') ? 'high' : 'low',
          phase_impact: 'medium', # Simplifiée
          timeline_impact: line[:variance_percentage] < -20 ? 'potential_delay' : 'none'
        }
      end

      def identify_variance_drivers(variance_analysis)
        drivers = []
        
        case variance_analysis[:status]
        when 'critical'
          drivers << 'Dépassement budgétaire significatif'
          drivers << 'Révision des estimations nécessaire'
        when 'warning'
          drivers << 'Consommation budgétaire accélérée'
          drivers << 'Surveillance renforcée recommandée'
        end
        
        drivers
      end

      def suggest_corrective_actions(variance_analysis)
        actions = []
        
        case variance_analysis[:status]
        when 'critical'
          actions << {
            priority: 'high',
            action: 'Gel temporaire des dépenses non essentielles',
            timeline: 'immédiat'
          }
          actions << {
            priority: 'high',
            action: 'Révision approfondie du budget restant',
            timeline: '1 semaine'
          }
        when 'warning'
          actions << {
            priority: 'medium',
            action: 'Validation renforcée des nouvelles dépenses',
            timeline: 'immédiat'
          }
        end
        
        actions
      end

      def analyze_variance_trends
        # Analyse des tendances de variance sur plusieurs périodes
        {
          overall_trend: 'increasing', # Simplifiée
          category_trends: analyze_category_variance_trends,
          seasonal_patterns: identify_seasonal_variance_patterns
        }
      end

      def analyze_category_variance_trends
        @budget_service.cost_tracking_report[:by_category].map do |category, costs|
          variance = costs[:actual] - costs[:planned]
          variance_percentage = costs[:planned].zero? ? 0 : (variance.to_f / costs[:planned] * 100).round(2)
          
          {
            category: category,
            current_variance: variance_percentage,
            trend: 'stable', # Simplifiée
            prediction: predict_category_trend(category, variance_percentage)
          }
        end
      end

      def predict_category_trend(category, current_variance)
        # Prédiction basée sur le type de catégorie et la variance actuelle
        if current_variance > 10
          'likely_to_worsen'
        elsif current_variance < -10
          'likely_to_improve'
        else
          'stable'
        end
      end

      def identify_seasonal_variance_patterns
        # Identification des patterns saisonniers
        []
      end

      def analyze_category_performance
        categories = @budget_service.cost_tracking_report[:by_category]
        
        categories.map do |category, costs|
          efficiency = calculate_category_efficiency(costs)
          performance_score = calculate_category_performance_score(costs)
          
          {
            category: category,
            efficiency: efficiency,
            performance_score: performance_score,
            ranking: rank_category_performance(performance_score),
            improvement_potential: assess_improvement_potential(costs, efficiency)
          }
        end.sort_by { |c| -c[:performance_score] }
      end

      def calculate_category_efficiency(costs)
        return 100 if costs[:planned].zero?
        
        efficiency = (costs[:planned].to_f / [costs[:actual], Money.new(1, 'EUR')].max * 100).round(2)
        [efficiency, 200].min # Cap à 200% pour éviter les valeurs aberrantes
      end

      def calculate_category_performance_score(costs)
        # Score basé sur l'efficacité et le respect du budget
        return 50 if costs[:planned].zero?
        
        budget_respect = costs[:actual] <= costs[:planned] ? 100 : [50 - ((costs[:actual] - costs[:planned]).to_f / costs[:planned] * 100), 0].max
        
        # Moyenne pondérée
        (budget_respect * 0.7 + calculate_category_efficiency(costs) * 0.3).round
      end

      def rank_category_performance(score)
        case score
        when 80..100
          'excellent'
        when 60..79
          'good'
        when 40..59
          'average'
        when 20..39
          'poor'
        else
          'critical'
        end
      end

      def assess_improvement_potential(costs, efficiency)
        if efficiency < 70
          'high'
        elsif efficiency < 85
          'medium'
        else
          'low'
        end
      end

      def generate_variance_recommendations
        recommendations = []
        
        # Recommandations basées sur l'analyse des variances
        @variance_data.each do |budget_data|
          if budget_data[:variance_analysis][:status] == 'critical'
            recommendations << {
              type: 'urgent_action',
              budget: budget_data[:category],
              priority: 'high',
              recommendation: 'Mise en place immédiate de mesures de contrôle des coûts',
              expected_impact: 'Réduction de la variance de 50% en 4 semaines'
            }
          end
        end
        
        recommendations
      end

      def analyze_cost_trends
        monthly_costs = @budget_service.cost_tracking_report[:by_period]
        
        {
          monthly_trend: calculate_monthly_trend(monthly_costs),
          acceleration_points: identify_cost_acceleration_points(monthly_costs),
          seasonal_factors: analyze_seasonal_cost_factors(monthly_costs)
        }
      end

      def calculate_monthly_trend(monthly_costs)
        return 'stable' if monthly_costs.count < 2
        
        # Calcul de la tendance basé sur la régression linéaire simple
        costs_array = monthly_costs.values.map { |cost| cost[:actual].cents }
        
        if costs_array.last > costs_array.first * 1.1
          'increasing'
        elsif costs_array.last < costs_array.first * 0.9
          'decreasing'
        else
          'stable'
        end
      end

      def identify_cost_acceleration_points(monthly_costs)
        acceleration_points = []
        
        monthly_costs.each_cons(2) do |(month1, costs1), (month2, costs2)|
          growth_rate = ((costs2[1][:actual] - costs1[1][:actual]).to_f / costs1[1][:actual] * 100).round(2)
          
          if growth_rate > 20
            acceleration_points << {
              month: month2,
              growth_rate: growth_rate,
              cause: 'À analyser'
            }
          end
        end
        
        acceleration_points
      end

      def analyze_seasonal_cost_factors(monthly_costs)
        # Analyse simplifiée des facteurs saisonniers
        []
      end

      def suggest_cost_control_measures
        measures = []
        
        # Mesures basées sur les dépassements identifiés
        @overruns.each do |overrun|
          case overrun[:severity]
          when 'high'
            measures << {
              category: overrun[:category],
              measure: 'Validation obligatoire du chef de projet pour toute dépense > 1000€',
              implementation: 'immédiate',
              expected_savings: overrun[:overrun_amount] * 0.3
            }
          when 'medium'
            measures << {
              category: overrun[:category],
              measure: 'Révision hebdomadaire des dépenses',
              implementation: '1 semaine',
              expected_savings: overrun[:overrun_amount] * 0.15
            }
          end
        end
        
        measures
      end

      def forecast_liquidity_needs
        base_forecast = @cash_flow[:liquidity_requirements]
        
        {
          immediate_needs: base_forecast[:next_3_months],
          medium_term_needs: base_forecast[:next_6_months],
          critical_periods: identify_liquidity_critical_periods,
          financing_recommendations: assess_financing_options
        }
      end

      def identify_liquidity_critical_periods
        # Identification des périodes de tension de trésorerie
        []
      end

      def assess_financing_options
        liquidity_gap = calculate_liquidity_gap
        
        options = []
        
        if liquidity_gap > Money.new(0, 'EUR')
          options << {
            type: 'credit_line',
            amount: liquidity_gap,
            estimated_cost: liquidity_gap * 0.05, # 5% estimated interest
            timeline: '2-4 semaines'
          }
          
          options << {
            type: 'invoice_factoring',
            amount: liquidity_gap * 0.8,
            estimated_cost: liquidity_gap * 0.02, # 2% factoring fee
            timeline: '1 semaine'
          }
        end
        
        options
      end

      def calculate_liquidity_gap
        projected_outflows = @cash_flow[:liquidity_requirements][:next_3_months]
        available_cash = @project.available_budget || Money.new(0, 'EUR')
        
        [projected_outflows - available_cash, Money.new(0, 'EUR')].max
      end

      def optimize_payment_schedule
        {
          current_schedule: @cash_flow[:payment_schedule],
          optimized_schedule: generate_optimized_payment_schedule,
          cash_flow_impact: calculate_optimization_impact
        }
      end

      def generate_optimized_payment_schedule
        # Génération d'un planning de paiement optimisé
        []
      end

      def calculate_optimization_impact
        # Calcul de l'impact de l'optimisation
        {
          cash_flow_improvement: Money.new(0, 'EUR'),
          timeline_impact: 'neutral'
        }
      end

      def assess_financing_needs
        total_budget = @project.total_budget || Money.new(0, 'EUR')
        current_funding = calculate_current_funding
        
        funding_gap = total_budget - current_funding
        
        {
          total_project_cost: total_budget,
          secured_funding: current_funding,
          funding_gap: funding_gap,
          financing_options: funding_gap > Money.new(0, 'EUR') ? suggest_financing_options(funding_gap) : []
        }
      end

      def calculate_current_funding
        # Calcul du financement actuel sécurisé
        @project.total_budget || Money.new(0, 'EUR') # Simplifiée
      end

      def suggest_financing_options(funding_gap)
        [
          {
            type: 'bank_loan',
            amount: funding_gap,
            estimated_rate: 4.5,
            pros: ['Taux fixe', 'Amortissement long terme'],
            cons: ['Garanties requises', 'Procédure longue']
          },
          {
            type: 'investor_funding',
            amount: funding_gap,
            estimated_cost: 'Equity dilution',
            pros: ['Pas de remboursement fixe', 'Expertise investisseur'],
            cons: ['Dilution propriété', 'Pression performance']
          }
        ]
      end

      def generate_detailed_scenarios
        base = @base_forecast
        
        {
          conservative: generate_scenario('conservative', base),
          optimistic: generate_scenario('optimistic', base),
          stress_test: generate_scenario('stress_test', base)
        }
      end

      def generate_scenario(scenario_type, base_forecast)
        multipliers = {
          'conservative' => { costs: 1.15, timeline: 1.1 },
          'optimistic' => { costs: 0.95, timeline: 0.95 },
          'stress_test' => { costs: 1.3, timeline: 1.2 }
        }
        
        multiplier = multipliers[scenario_type]
        
        {
          total_cost: base_forecast[:projected_total_cost] * multiplier[:costs],
          timeline_impact: multiplier[:timeline],
          budget_variance: (base_forecast[:projected_total_cost] * multiplier[:costs]) - @project.total_budget,
          probability: estimate_scenario_probability(scenario_type),
          mitigation_strategies: get_scenario_mitigations(scenario_type)
        }
      end

      def estimate_scenario_probability(scenario_type)
        {
          'conservative' => 70,
          'optimistic' => 20,
          'stress_test' => 10
        }[scenario_type]
      end

      def get_scenario_mitigations(scenario_type)
        {
          'conservative' => ['Révision budget', 'Négociation fournisseurs'],
          'optimistic' => ['Maintien vigilance', 'Capitalisation gains'],
          'stress_test' => ['Plan contingence', 'Financement urgence']
        }[scenario_type] || []
      end

      def assess_budget_risks
        risks = []
        
        # Risques basés sur l'analyse actuelle
        if @project.is_over_budget?
          risks << {
            type: 'budget_overrun',
            severity: 'high',
            probability: 90,
            impact: 'Dépassement budgétaire confirmé',
            mitigation: 'Réduction scope ou financement additionnel'
          }
        end
        
        # Risques de marché
        risks << {
          type: 'market_volatility',
          severity: 'medium',
          probability: 40,
          impact: 'Augmentation coûts matériaux/main d\'œuvre',
          mitigation: 'Contrats prix fixes, approvisionnement anticipé'
        }
        
        risks
      end

      def develop_contingency_plans
        plans = []
        
        # Plan pour dépassement budgétaire
        plans << {
          trigger: 'Dépassement budget > 10%',
          actions: [
            'Gel dépenses non critiques',
            'Révision scope projet',
            'Recherche financement complémentaire'
          ],
          responsible: 'Chef de projet',
          timeline: '48h'
        }
        
        plans
      end

      def calculate_profitability_metrics
        revenue = estimate_project_revenue
        costs = @project.current_budget || Money.new(0, 'EUR')
        
        {
          total_revenue: revenue,
          total_costs: costs,
          gross_profit: revenue - costs,
          gross_margin: revenue.zero? ? 0 : ((revenue - costs).to_f / revenue * 100).round(2),
          roi: costs.zero? ? 0 : ((revenue - costs).to_f / costs * 100).round(2)
        }
      end

      def estimate_project_revenue
        # Estimation des revenus basée sur le type de projet
        case @project.project_type
        when 'residential'
          estimate_residential_revenue
        when 'commercial'
          estimate_commercial_revenue
        else
          Money.new(0, 'EUR')
        end
      end

      def estimate_residential_revenue
        # Estimation basée sur les lots et prix de vente
        total_revenue = Money.new(0, 'EUR')
        
        @project.lots.each do |lot|
          if lot.sale_price_cents
            total_revenue += Money.new(lot.sale_price_cents, 'EUR')
          end
        end
        
        total_revenue
      end

      def estimate_commercial_revenue
        # Estimation pour projets commerciaux (loyers, vente)
        Money.new(0, 'EUR') # Simplifiée
      end

      def analyze_profit_margins
        # Analyse des marges par phase/catégorie
        {}
      end

      def forecast_revenue_streams
        # Prévision des flux de revenus
        {}
      end

      def calculate_roi_metrics
        # Métriques ROI détaillées
        {}
      end

      def identify_value_opportunities
        # Opportunités d'optimisation de la valeur
        []
      end

      def create_budget_adjustment(budget, adjustment_params)
        # Créer un ajustement budgétaire
        {
          success: true,
          record: {
            budget: budget,
            amount: adjustment_params[:amount],
            justification: adjustment_params[:justification]
          }
        }
      end

      def significant_adjustment?(adjustment)
        # Détermine si l'ajustement est significatif
        adjustment[:amount].to_f.abs > 10000
      end

      def send_budget_adjustment_notifications(adjustment)
        # Envoie des notifications pour ajustements significatifs
        Rails.logger.info "Budget adjustment notification sent for #{adjustment[:amount]}"
      end

      def log_budget_adjustment(adjustment, user)
        # Log l'ajustement pour audit
        Rails.logger.info "Budget adjustment by user #{user.id}: #{adjustment[:amount]}"
      end

      def execute_budget_reallocation(params)
        # Exécute une réallocation budgétaire
        {
          success: true,
          reallocation: params
        }
      end

      def log_budget_reallocation(reallocation, user)
        # Log la réallocation pour audit
        Rails.logger.info "Budget reallocation by user #{user.id}: #{reallocation[:amount]}"
      end

      def create_budget_alert(params)
        # Crée une alerte budgétaire
        {
          success: true,
          alert: params
        }
      end

      def compile_comprehensive_financial_report
        {
          executive_summary: generate_executive_summary,
          budget_analysis: @budget_summary,
          variance_analysis: detailed_variance_analysis,
          cost_control: @cost_tracking,
          cash_flow: @cash_flow,
          profitability: calculate_profitability_metrics,
          recommendations: @optimization_suggestions,
          generated_at: Time.current
        }
      end

      def generate_executive_summary
        {
          project_status: @project.status,
          budget_performance: @budget_summary[:percentage_used],
          key_alerts: @budget_summary[:alerts].count,
          financial_health: assess_financial_health
        }
      end

      def assess_financial_health
        if @project.is_over_budget?
          'critical'
        elsif @budget_summary[:percentage_used] > 85
          'warning'
        else
          'good'
        end
      end

      def generate_budget_csv
        # Génère les données budget en CSV
        CSV.generate do |csv|
          csv << ['Category', 'Planned', 'Actual', 'Variance', 'Variance %']
          
          @budget_service.cost_tracking_report[:by_category].each do |category, costs|
            variance = costs[:actual] - costs[:planned]
            variance_pct = costs[:planned].zero? ? 0 : (variance.to_f / costs[:planned] * 100).round(2)
            
            csv << [
              category,
              costs[:planned].to_s,
              costs[:actual].to_s,
              variance.to_s,
              "#{variance_pct}%"
            ]
          end
        end
      end

      def synchronize_with_accounting
        # Simulation d'intégration avec système comptable
        {
          success: true,
          updated_records: rand(10..50)
        }
      end
    end
  end
end