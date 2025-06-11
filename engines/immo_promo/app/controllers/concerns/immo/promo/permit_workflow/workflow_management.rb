module Immo
  module Promo
    module PermitWorkflow
      module WorkflowManagement
        extend ActiveSupport::Concern

        def generate_workflow_for_project_type(project_type)
          base_workflow = [
            {
              step: 1,
              name: 'Étude de faisabilité',
              description: 'Analyse réglementaire et contraintes',
              permits_required: ['declaration'],
              estimated_duration: '2-4 semaines'
            },
            {
              step: 2,
              name: 'Dépôt permis d\'urbanisme',
              description: 'Déclaration préalable ou permis de construire',
              permits_required: ['urban_planning', 'construction'],
              estimated_duration: '2-4 mois'
            },
            {
              step: 3,
              name: 'Autorisations techniques',
              description: 'Raccordements et sécurité',
              permits_required: ['environmental'],
              estimated_duration: '1-2 mois'
            }
          ]

          # Adapter selon le type de projet
          case project_type
          when 'residential'
            base_workflow + residential_specific_steps
          when 'commercial'
            base_workflow + commercial_specific_steps
          when 'industrial'
            base_workflow + industrial_specific_steps
          else
            base_workflow
          end
        end

        def determine_current_workflow_step
          workflow_steps = generate_workflow_for_project_type(@project.project_type)
          
          workflow_steps.each_with_index do |step, index|
            required_permits = step[:permits_required]
            completed_permits = @project.permits.where(permit_type: required_permits, status: 'approved').count
            
            # Si tous les permis requis pour cette étape ne sont pas complétés, c'est l'étape courante
            return index + 1 if completed_permits < required_permits.count
          end
          
          workflow_steps.count + 1 # Toutes les étapes terminées
        end

        def calculate_completed_steps
          current_step = determine_current_workflow_step
          current_step - 1
        end

        def calculate_permit_dependencies
          dependencies = {}
          
          @project.permits.each do |permit|
            permit_dependencies = []
            
            case permit.permit_type
            when 'construction'
              # Dépend du permis d'urbanisme
              urban_permit = @project.permits.find_by(permit_type: 'urban_planning')
              permit_dependencies << urban_permit if urban_permit
            when 'technical_authorizations'
              # Dépend du permis de construire
              construction_permit = @project.permits.find_by(permit_type: 'construction')
              permit_dependencies << construction_permit if construction_permit
            end
            
            dependencies[permit.id] = permit_dependencies
          end
          
          dependencies
        end

        def identify_blocking_permits
          blocking = []
          dependencies = calculate_permit_dependencies
          
          dependencies.each do |permit_id, deps|
            permit = @project.permits.find(permit_id)
            
            deps.each do |dependency|
              unless dependency.approved?
                blocking << {
                  blocked_permit: permit,
                  blocking_permit: dependency,
                  impact: calculate_blocking_impact(permit, dependency)
                }
              end
            end
          end
          
          blocking
        end

        def assess_construction_readiness
          critical_permits = %w[urban_planning construction]
          critical_approved = @project.permits.where(permit_type: critical_permits, status: 'approved').count
          
          technical_permits = %w[technical_authorizations]
          technical_approved = @project.permits.where(permit_type: technical_permits, status: 'approved').count
          
          {
            critical_permits_ready: critical_approved == critical_permits.count,
            technical_permits_ready: technical_approved == technical_permits.count,
            overall_readiness: calculate_overall_readiness_percentage,
            missing_permits: identify_missing_permits_for_construction,
            next_milestone: identify_next_construction_milestone
          }
        end

        private

        def residential_specific_steps
          [
            {
              step: 4,
              name: 'Conformité accessibilité',
              description: 'Validation normes PMR',
              permits_required: ['modification'],
              estimated_duration: '2-3 semaines'
            }
          ]
        end

        def commercial_specific_steps
          [
            {
              step: 4,
              name: 'Autorisation commerciale',
              description: 'Commission départementale d\'aménagement commercial',
              permits_required: ['modification'],
              estimated_duration: '3-6 mois'
            },
            {
              step: 5,
              name: 'Sécurité incendie',
              description: 'Validation ERP',
              permits_required: ['demolition'],
              estimated_duration: '1-2 mois'
            }
          ]
        end

        def industrial_specific_steps
          [
            {
              step: 4,
              name: 'Étude d\'impact environnemental',
              description: 'ICPE et évaluation environnementale',
              permits_required: ['environmental', 'demolition'],
              estimated_duration: '6-12 mois'
            },
            {
              step: 5,
              name: 'Autorisations DREAL',
              description: 'Exploitation installations classées',
              permits_required: ['modification'],
              estimated_duration: '3-6 mois'
            }
          ]
        end

        def calculate_blocking_impact(blocked_permit, blocking_permit)
          # Calcule l'impact du blocage sur le planning
          if blocking_permit.status == 'denied'
            'critical' # Refus = impact critique
          elsif blocking_permit.submitted? && blocking_permit.processing_overdue?
            'high' # En retard = impact élevé
          else
            'medium' # En cours normal = impact modéré
          end
        end

        def calculate_overall_readiness_percentage
          total_required = get_required_permits_for_construction.count
          return 0 if total_required.zero?
          
          approved_count = @project.permits.where(
            permit_type: get_required_permits_for_construction,
            status: 'approved'
          ).count
          
          (approved_count.to_f / total_required * 100).round
        end

        def get_required_permits_for_construction
          case @project.project_type
          when 'residential'
            %w[urban_planning construction environmental modification]
          when 'commercial'
            %w[urban_planning construction environmental modification demolition]
          when 'industrial'
            %w[urban_planning construction environmental modification demolition declaration]
          else
            %w[urban_planning construction environmental]
          end
        end

        def identify_missing_permits_for_construction
          required = get_required_permits_for_construction
          existing = @project.permits.approved.pluck(:permit_type)
          
          required - existing
        end

        def identify_next_construction_milestone
          missing_permits = identify_missing_permits_for_construction
          return "Construction autorisée" if missing_permits.empty?
          
          # Retourne le prochain permis critique à obtenir
          critical_missing = missing_permits & %w[urban_planning construction]
          return critical_missing.first.humanize if critical_missing.any?
          
          missing_permits.first.humanize
        end
      end
    end
  end
end