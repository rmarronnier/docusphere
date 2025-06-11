module Immo
  module Promo
    module PermitWorkflow
      module ComplianceTracking
        extend ActiveSupport::Concern

        def validate_condition
          @permit = @project.permits.find(params[:permit_id])
          @condition = @permit.permit_conditions.find(params[:condition_id])
          
          validation_result = validate_permit_condition(@condition, params[:validation_data])
          
          if validation_result[:valid]
            @condition.update(
              status: 'validated',
              validated_at: Date.current,
              validated_by: current_user,
              validation_notes: params[:validation_notes]
            )
            flash[:success] = "Condition validée avec succès"
          else
            flash[:error] = "Condition non validée : #{validation_result[:errors].join(', ')}"
          end
          
          redirect_to immo_promo_engine.project_permit_workflow_compliance_checklist_path(@project)
        end

        def get_regulatory_requirements_for_project
          # Retourne les exigences réglementaires spécifiques au projet
          case @project.project_type
          when 'residential'
            residential_requirements
          when 'commercial'
            commercial_requirements
          when 'industrial'
            industrial_requirements
          else
            basic_requirements
          end
        end

        def identify_missing_documents
          required_docs = get_required_documents_for_project
          existing_docs = @project.documents.pluck(:document_type)
          
          required_docs.reject { |doc| existing_docs.include?(doc) }
        end

        def check_permit_conditions_compliance
          compliance_data = {}
          
          @project.permits.approved.includes(:permit_conditions).each do |permit|
            permit_compliance = {
              permit: permit,
              conditions: permit.permit_conditions.map do |condition|
                {
                  condition: condition,
                  status: condition.status,
                  compliance_level: assess_condition_compliance(condition),
                  required_actions: get_condition_required_actions(condition)
                }
              end
            }
            
            compliance_data[permit.id] = permit_compliance
          end
          
          compliance_data
        end

        private

        def residential_requirements
          [
            {
              category: 'Urbanisme',
              requirements: [
                'Respect du PLU/POS',
                'Coefficient d\'emprise au sol',
                'Hauteur maximale',
                'Reculs par rapport aux limites'
              ]
            },
            {
              category: 'Accessibilité',
              requirements: [
                'Normes PMR',
                'Ascenseur si > R+3',
                'Cheminements accessibles'
              ]
            },
            {
              category: 'Thermique',
              requirements: [
                'RT 2012/RE 2020',
                'Isolation thermique',
                'Ventilation mécanique'
              ]
            }
          ]
        end

        def commercial_requirements
          [
            {
              category: 'Urbanisme Commercial',
              requirements: [
                'Autorisation CDAC si > 1000m²',
                'Étude d\'impact commercial',
                'Accessibilité véhicules'
              ]
            },
            {
              category: 'Sécurité Incendie',
              requirements: [
                'Classement ERP',
                'Système de sécurité incendie',
                'Issues de secours'
              ]
            }
          ]
        end

        def industrial_requirements
          [
            {
              category: 'Environnement',
              requirements: [
                'Étude d\'impact si requis',
                'Autorisation ICPE',
                'Gestion des déchets'
              ]
            },
            {
              category: 'Sécurité Industrielle',
              requirements: [
                'Plan de prévention',
                'Évaluation risques SEVESO',
                'Formation sécurité'
              ]
            }
          ]
        end

        def basic_requirements
          [
            {
              category: 'Base',
              requirements: [
                'Permis de construire',
                'Raccordements techniques'
              ]
            }
          ]
        end

        def get_required_documents_for_project
          # Liste des documents requis selon le type de projet
          case @project.project_type
          when 'residential'
            %w[plans_masse plans_facades etude_thermique notice_accessibilite]
          when 'commercial'
            %w[plans_masse plans_facades etude_impact_commercial notice_securite_incendie]
          when 'industrial'
            %w[plans_masse plans_facades etude_impact_environnemental dossier_icpe]
          else
            %w[plans_masse plans_facades]
          end
        end

        def assess_condition_compliance(condition)
          # Évalue le niveau de conformité d'une condition
          case condition.status
          when 'validated'
            'compliant'
          when 'in_progress'
            'partially_compliant'
          when 'pending'
            'non_compliant'
          else
            'unknown'
          end
        end

        def get_condition_required_actions(condition)
          return [] if condition.status == 'validated'
          
          # Actions spécifiques selon le type de condition
          case condition.condition_type
          when 'technical_study'
            ['Réaliser l\'étude technique', 'Faire valider par bureau de contrôle']
          when 'environmental_measure'
            ['Mettre en place les mesures compensatoires', 'Obtenir validation environnementale']
          when 'accessibility_compliance'
            ['Adapter les plans pour conformité PMR', 'Valider avec commission accessibilité']
          else
            ['Vérifier les exigences spécifiques', 'Soumettre les justificatifs']
          end
        end

        def validate_permit_condition(condition, validation_data)
          # Valide une condition de permis
          {
            valid: validation_data.present?,
            errors: validation_data.present? ? [] : ['Données de validation manquantes']
          }
        end
      end
    end
  end
end