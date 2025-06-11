module Immo
  module Promo
    module VarianceAnalyzable
      extend ActiveSupport::Concern

      private

      def analyze_budget_variance(budget_lines, current_budget, total_budget)
        overall_variance = current_budget - total_budget
        variance_percentage = total_budget > 0 ? (overall_variance.to_f / total_budget * 100).round(2) : 0
        
        {
          total_budget: total_budget,
          current_spent: current_budget,
          variance: overall_variance,
          variance_percentage: variance_percentage,
          status: determine_variance_status(variance_percentage),
          by_line: analyze_lines_variance(budget_lines),
          drivers: identify_variance_drivers(variance_percentage),
          corrective_actions: suggest_corrective_actions(variance_percentage)
        }
      end

      def determine_variance_status(variance_percentage)
        if variance_percentage.abs <= 5
          'on_track'
        elsif variance_percentage.abs <= 15
          'warning'
        else
          'critical'
        end
      end

      def analyze_lines_variance(budget_lines)
        budget_lines.map do |line|
          variance_percentage = calculate_line_variance_percentage(line)
          
          line.merge(
            variance_percentage: variance_percentage,
            variance_category: categorize_variance(variance_percentage),
            variance_trend: calculate_line_trend(line),
            impact_assessment: assess_variance_impact(line)
          )
        end
      end

      def calculate_line_variance_percentage(line)
        return 0 unless line[:planned_amount] && line[:planned_amount] > 0
        
        actual = line[:actual_amount] || 0
        ((actual - line[:planned_amount]).to_f / line[:planned_amount] * 100).round(2)
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
        variance_amount = (line[:actual_amount] || 0) - (line[:planned_amount] || 0)
        
        {
          project_impact: variance_amount.abs > 50000 ? 'high' : 'low',
          phase_impact: 'medium', # Simplifiée
          timeline_impact: calculate_line_variance_percentage(line) < -20 ? 'potential_delay' : 'none'
        }
      end

      def identify_variance_drivers(variance_percentage)
        drivers = []
        
        if variance_percentage > 15
          drivers << 'Dépassement budgétaire significatif'
          drivers << 'Révision des estimations nécessaire'
        elsif variance_percentage > 5
          drivers << 'Consommation budgétaire accélérée'
          drivers << 'Surveillance renforcée recommandée'
        elsif variance_percentage < -15
          drivers << 'Sous-utilisation importante du budget'
          drivers << 'Retards potentiels dans l\'exécution'
        end
        
        drivers
      end

      def suggest_corrective_actions(variance_percentage)
        actions = []
        
        if variance_percentage > 15
          actions << { 
            action: 'Réviser les estimations budgétaires',
            urgency: 'high',
            responsible: 'project_manager'
          }
          actions << {
            action: 'Négocier avec les fournisseurs',
            urgency: 'high',
            responsible: 'procurement'
          }
        elsif variance_percentage > 5
          actions << {
            action: 'Analyser les postes de dépassement',
            urgency: 'medium',
            responsible: 'financial_controller'
          }
          actions << {
            action: 'Optimiser les dépenses restantes',
            urgency: 'medium',
            responsible: 'project_manager'
          }
        elsif variance_percentage < -15
          actions << {
            action: 'Accélérer l\'exécution des travaux',
            urgency: 'medium',
            responsible: 'project_manager'
          }
          actions << {
            action: 'Réallouer le budget disponible',
            urgency: 'low',
            responsible: 'financial_controller'
          }
        end
        
        actions
      end

      def analyze_variance_trends(historical_data)
        return [] unless historical_data.present?
        
        historical_data.map do |period|
          {
            period: period[:date],
            variance: period[:variance],
            trend: calculate_trend_direction(period[:variance], period[:previous_variance])
          }
        end
      end

      def calculate_trend_direction(current_variance, previous_variance)
        return 'stable' unless previous_variance
        
        change = current_variance - previous_variance
        
        if change.abs < 2
          'stable'
        elsif change > 0
          'deteriorating'
        else
          'improving'
        end
      end
    end
  end
end