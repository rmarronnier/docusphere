module Immo
  module Promo
    class ProjectResourceService
      module UtilizationMetrics
        def calculate_utilization_metrics
          stakeholders = project.stakeholders.active
          utilizations = stakeholders.map { |s| calculate_utilization_percentage(s) }
          
          {
            average_utilization: utilizations.sum / utilizations.count.to_f,
            min_utilization: utilizations.min,
            max_utilization: utilizations.max,
            standard_deviation: calculate_standard_deviation(utilizations),
            efficiency_index: calculate_resource_efficiency
          }
        end

        def calculate_utilization_percentage(stakeholder)
          allocated_hours = calculate_allocated_hours(stakeholder)
          # Base sur 40 heures par semaine
          weekly_capacity = 40
          
          # Si le stakeholder a plus d'heures allouées que sa capacité hebdomadaire,
          # calculer le pourcentage basé sur sa charge actuelle
          (allocated_hours.to_f / weekly_capacity * 100).round(2)
        end

        private

        def calculate_standard_deviation(values)
          return 0 if values.empty? || values.size == 1
          
          mean = values.sum / values.size.to_f
          variance = values.sum { |v| (v - mean) ** 2 } / values.size.to_f
          Math.sqrt(variance).round(2)
        end

        def calculate_resource_efficiency
          # Efficiency based on balanced utilization
          utilizations = project.stakeholders.active.map { |s| calculate_utilization_percentage(s) }
          
          optimal_range = utilizations.count { |u| u.between?(70, 90) }
          total = utilizations.count
          
          return 0 if total == 0
          (optimal_range.to_f / total * 100).round(2)
        end
      end
    end
  end
end