module Immo
  module Promo
    class RegulatoryComplianceService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def check_all_compliance
        {
          rt2020: check_rt2020_compliance,
          accessibility: check_accessibility_compliance,
          fire_safety: check_fire_safety_compliance,
          environmental: check_environmental_compliance,
          urban_planning: check_urban_planning_compliance,
          overall_compliance: calculate_overall_compliance
        }
      end

      def check_regulatory_compliance
        compliance_issues = []
        
        compliance_issues.concat(rt2020_issues)
        compliance_issues.concat(accessibility_issues)
        compliance_issues.concat(fire_safety_issues)
        compliance_issues.concat(environmental_issues)
        
        compliance_issues.compact
      end

      def check_permit_conditions_compliance
        issues = []
        
        project.permits.approved.each do |permit|
          unmet_conditions = permit.permit_conditions.where(is_fulfilled: false)
          
          if unmet_conditions.any?
            issues << {
              type: 'unmet_conditions',
              permit: permit,
              conditions: unmet_conditions,
              severity: calculate_condition_severity(unmet_conditions),
              message: "#{unmet_conditions.count} conditions non remplies pour #{permit.permit_type.humanize}",
              action_required: 'Remplir les conditions avant le démarrage des travaux'
            }
          end
        end
        
        issues
      end

      def compliance_summary
        total_issues = check_regulatory_compliance
        critical_issues = total_issues.select { |issue| issue[:severity] == 'critical' }
        high_issues = total_issues.select { |issue| issue[:severity] == 'high' }
        
        {
          total_issues: total_issues.count,
          critical_count: critical_issues.count,
          high_count: high_issues.count,
          compliance_score: calculate_compliance_score(total_issues),
          ready_for_construction: critical_issues.empty?,
          issues_by_category: group_issues_by_category(total_issues)
        }
      end

      private

      def check_rt2020_compliance
        missing_specs = find_lots_missing_environmental_specs
        
        {
          compliant: missing_specs.empty?,
          missing_specifications: missing_specs.count,
          affected_lots: missing_specs,
          message: missing_specs.empty? ? 
            'Toutes les spécifications RT 2020 sont complètes' :
            "#{missing_specs.count} lots sans spécifications environnementales"
        }
      end

      def check_accessibility_compliance
        return { compliant: true, message: 'Non applicable' } unless project.residential?
        
        required_accessible = calculate_required_accessible_units
        actual_accessible = count_accessible_units
        
        {
          compliant: actual_accessible >= required_accessible,
          required: required_accessible,
          actual: actual_accessible,
          deficit: [required_accessible - actual_accessible, 0].max,
          message: build_accessibility_message(required_accessible, actual_accessible)
        }
      end

      def check_fire_safety_compliance
        has_approval = project.permits.approved.where(permit_type: 'fire_safety').exists?
        has_study = project.documents.where(document_type: 'fire_safety_study').exists?
        
        {
          compliant: has_approval || !requires_fire_safety_approval?,
          has_approval: has_approval,
          has_study: has_study,
          required: requires_fire_safety_approval?,
          message: build_fire_safety_message(has_approval, has_study)
        }
      end

      def check_environmental_compliance
        requires_impact_study = project.total_surface_area && project.total_surface_area > 10000
        has_impact_study = project.documents.where(document_type: 'environmental_impact').exists?
        
        {
          compliant: !requires_impact_study || has_impact_study,
          requires_study: requires_impact_study,
          has_study: has_impact_study,
          message: build_environmental_message(requires_impact_study, has_impact_study)
        }
      end

      def check_urban_planning_compliance
        plu_compliant = check_plu_compliance
        density_compliant = check_density_compliance
        
        {
          compliant: plu_compliant && density_compliant,
          plu_compliant: plu_compliant,
          density_compliant: density_compliant,
          message: build_urban_planning_message(plu_compliant, density_compliant)
        }
      end

      def rt2020_issues
        missing_specs = find_lots_missing_environmental_specs
        
        return [] if missing_specs.empty?
        
        [{
          regulation: 'RT 2020',
          severity: 'critical',
          description: "Spécifications environnementales manquantes pour #{missing_specs.count} lots",
          action: 'Compléter les spécifications RT 2020 pour tous les lots',
          affected_lots: missing_specs.map(&:lot_number)
        }]
      end

      def accessibility_issues
        return [] unless project.residential? && project.total_units && project.total_units > 20
        
        required = calculate_required_accessible_units
        actual = count_accessible_units
        
        return [] if actual >= required
        
        [{
          regulation: 'Accessibilité PMR',
          severity: 'high',
          description: "#{required} logements accessibles requis, #{actual} prévus",
          action: 'Modifier la conception pour respecter le quota PMR',
          deficit: required - actual
        }]
      end

      def fire_safety_issues
        return [] unless requires_fire_safety_approval?
        
        has_approval = project.permits.approved.where(permit_type: 'fire_safety').exists?
        return [] if has_approval
        
        [{
          regulation: 'Sécurité incendie',
          severity: 'critical',
          description: 'Avis de la commission de sécurité manquant',
          action: 'Soumettre le dossier à la commission de sécurité'
        }]
      end

      def environmental_issues
        return [] unless project.total_surface_area && project.total_surface_area > 10000
        
        has_study = project.documents.where(document_type: 'environmental_impact').exists?
        has_permit = project.permits.where(permit_type: 'environmental').exists?
        
        issues = []
        
        unless has_study
          issues << {
            regulation: 'Environnement',
            severity: 'high',
            description: 'Étude d\'impact environnemental requise',
            action: 'Réaliser une étude d\'impact environnemental'
          }
        end
        
        unless has_permit
          issues << {
            regulation: 'Environnement',
            severity: 'critical',
            description: 'Autorisation environnementale requise',
            action: 'Déposer une demande d\'autorisation environnementale'
          }
        end
        
        issues
      end

      def find_lots_missing_environmental_specs
        return [] unless project.lots.any?
        
        project.lots.left_joins(:lot_specifications)
                    .where.not(
                      id: project.lots.joins(:lot_specifications)
                                      .where(immo_promo_lot_specifications: { category: 'environmental' })
                                      .select(:id)
                    )
      end

      def calculate_required_accessible_units
        return 0 unless project.total_units
        
        if project.total_units <= 20
          0
        elsif project.total_units <= 100
          (project.total_units * 0.05).ceil
        else
          (project.total_units * 0.10).ceil
        end
      end

      def count_accessible_units
        project.lots.joins(:lot_specifications)
                    .where(immo_promo_lot_specifications: { accessibility_features: true })
                    .count
      end

      def requires_fire_safety_approval?
        return false unless project.project_type
        
        case project.project_type
        when 'high_rise'
          true
        when 'commercial'
          project.total_surface_area && project.total_surface_area > 1000
        when 'mixed_use'
          true
        else
          project.total_units && project.total_units > 50
        end
      end

      def check_plu_compliance
        # Simplified - would check against actual PLU rules
        true
      end

      def check_density_compliance
        return true unless project.land_area && project.buildable_surface_area
        
        density = project.buildable_surface_area.to_f / project.land_area
        density <= 0.7 # Maximum 70% land coverage
      end

      def calculate_condition_severity(conditions)
        return 'low' if conditions.empty?
        
        critical_keywords = ['sécurité', 'structure', 'fondation', 'incendie']
        high_keywords = ['environnement', 'accessibilité', 'évacuation']
        
        conditions.each do |condition|
          description = condition.description.to_s.downcase
          return 'critical' if critical_keywords.any? { |kw| description.include?(kw) }
          return 'high' if high_keywords.any? { |kw| description.include?(kw) }
        end
        
        'medium'
      end

      def calculate_compliance_score(issues)
        return 100 if issues.empty?
        
        deductions = issues.sum do |issue|
          case issue[:severity]
          when 'critical' then 20
          when 'high' then 10
          when 'medium' then 5
          else 2
          end
        end
        
        [100 - deductions, 0].max
      end

      def calculate_overall_compliance
        checks = [
          check_rt2020_compliance[:compliant],
          check_accessibility_compliance[:compliant],
          check_fire_safety_compliance[:compliant],
          check_environmental_compliance[:compliant],
          check_urban_planning_compliance[:compliant]
        ]
        
        compliant_count = checks.count(true)
        total_count = checks.count
        
        {
          score: (compliant_count.to_f / total_count * 100).round,
          compliant_areas: compliant_count,
          total_areas: total_count,
          fully_compliant: compliant_count == total_count
        }
      end

      def group_issues_by_category(issues)
        issues.group_by { |issue| issue[:regulation] }
              .transform_values { |v| v.count }
      end

      def build_accessibility_message(required, actual)
        if actual >= required
          "Conforme : #{actual} logements accessibles (#{required} requis)"
        else
          "Non conforme : #{actual} logements accessibles sur #{required} requis"
        end
      end

      def build_fire_safety_message(has_approval, has_study)
        if has_approval
          "Conforme : Avis favorable de la commission de sécurité"
        elsif has_study
          "En cours : Étude de sécurité réalisée, en attente d'avis"
        else
          "Non conforme : Dossier de sécurité incendie à constituer"
        end
      end

      def build_environmental_message(requires_study, has_study)
        if !requires_study
          "Non applicable : Surface < 10 000 m²"
        elsif has_study
          "Conforme : Étude d'impact environnemental réalisée"
        else
          "Non conforme : Étude d'impact environnemental requise"
        end
      end

      def build_urban_planning_message(plu_compliant, density_compliant)
        messages = []
        messages << "PLU : #{plu_compliant ? 'Conforme' : 'Non conforme'}"
        messages << "Densité : #{density_compliant ? 'Conforme' : 'Non conforme'}"
        messages.join(', ')
      end
    end
  end
end