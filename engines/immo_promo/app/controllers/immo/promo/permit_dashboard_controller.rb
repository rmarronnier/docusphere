module Immo
  module Promo
    class PermitDashboardController < Immo::Promo::ApplicationController
      before_action :set_project
      before_action :authorize_permit_access

      def show
        @permit_tracker = PermitTrackerService.new(@project, current_user)
        @permit_status = @permit_tracker.track_permit_status
        @critical_permits = @permit_tracker.critical_permits_status
        @compliance_check = @permit_tracker.compliance_check
        @bottlenecks = @permit_tracker.identify_bottlenecks
        @next_actions = @permit_tracker.suggest_next_actions
        
        respond_to do |format|
          format.html
          format.json { render json: permit_dashboard_data }
        end
      end

      def workflow_guide
        @permit_tracker = PermitTrackerService.new(@project, current_user)
        @project_type = @project.project_type
        @current_phase = @project.current_phase
        
        # Générer le workflow spécifique au type de projet
        @workflow_steps = generate_workflow_for_project_type(@project_type)
        @current_step = determine_current_workflow_step
        @completed_steps = calculate_completed_steps
        @next_required_actions = @permit_tracker.suggest_next_actions.select { |a| a[:urgency] == :critical }
      end

      def compliance_checklist
        @permit_tracker = PermitTrackerService.new(@project, current_user)
        @compliance_data = @permit_tracker.compliance_check
        @regulatory_requirements = get_regulatory_requirements_for_project
        @missing_documents = identify_missing_documents
        @condition_compliance = check_permit_conditions_compliance
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def authorize_permit_access
        authorize @project, :manage_permits?
      end

      def permit_dashboard_data
        {
          project: {
            id: @project.id,
            name: @project.name,
            type: @project.project_type
          },
          permit_status: @permit_status,
          critical_permits: @critical_permits,
          compliance_check: @compliance_check,
          bottlenecks: @bottlenecks,
          next_actions: @next_actions
        }
      end

      def generate_workflow_for_project_type(project_type)
        case project_type
        when 'residential'
          residential_permit_workflow
        when 'commercial'
          commercial_permit_workflow
        when 'mixed'
          mixed_permit_workflow
        else
          standard_permit_workflow
        end
      end

      def residential_permit_workflow
        [
          { step: 1, name: 'Déclaration préalable', description: 'DP ou PC selon surface', required: true },
          { step: 2, name: 'Permis de construire', description: 'PC si surface > 150m²', required: true },
          { step: 3, name: 'Déclaration ouverture chantier', description: 'DOC avant démarrage', required: true },
          { step: 4, name: 'Contrôles conformité', description: 'Visites réglementaires', required: true },
          { step: 5, name: 'Déclaration achèvement', description: 'DAACT en fin de travaux', required: true }
        ]
      end

      def commercial_permit_workflow
        [
          { step: 1, name: 'Autorisation commerciale', description: 'CDAC si > 1000m²', required: true },
          { step: 2, name: 'Permis de construire', description: 'PC avec volet paysager', required: true },
          { step: 3, name: 'Autorisation voirie', description: 'Si modification accès', required: false },
          { step: 4, name: 'Déclaration ouverture chantier', description: 'DOC avant démarrage', required: true },
          { step: 5, name: 'Contrôles techniques', description: 'Visites réglementaires', required: true },
          { step: 6, name: 'Autorisation exploitation', description: 'Avant ouverture au public', required: true },
          { step: 7, name: 'Déclaration achèvement', description: 'DAACT en fin de travaux', required: true }
        ]
      end

      def mixed_permit_workflow
        residential_permit_workflow + commercial_permit_workflow.select { |step| !step[:name].include?('construire') }
      end

      def standard_permit_workflow
        [
          { step: 1, name: 'Consultation préalable', description: 'Vérification faisabilité', required: false },
          { step: 2, name: 'Permis de construire', description: 'Dépôt dossier PC', required: true },
          { step: 3, name: 'Déclaration ouverture chantier', description: 'DOC avant démarrage', required: true },
          { step: 4, name: 'Déclaration achèvement', description: 'DAACT en fin de travaux', required: true }
        ]
      end

      def determine_current_workflow_step
        # Logique pour déterminer l'étape actuelle basée sur les permis existants
        submitted_permits = @project.permits.where.not(status: ['draft', 'pending'])
        return 1 if submitted_permits.empty?
        
        # Trouver la dernière étape complétée
        completed_steps = submitted_permits.where(status: ['approved', 'completed']).count
        completed_steps + 1
      end

      def calculate_completed_steps
        @project.permits.where(status: ['approved', 'completed']).count
      end

      def get_regulatory_requirements_for_project
        # Retourner les exigences réglementaires basées sur le type de projet et la localisation
        {
          urbanisme: urbanisme_requirements,
          environnement: environmental_requirements,
          securite: safety_requirements,
          accessibilite: accessibility_requirements
        }
      end

      def urbanisme_requirements
        [
          'Respect du PLU/POS',
          'Coefficient d\'occupation des sols',
          'Hauteur maximale autorisée',
          'Reculs par rapport aux limites',
          'Stationnement réglementaire'
        ]
      end

      def environmental_requirements
        requirements = ['Étude d\'impact si nécessaire']
        
        if @project.surface_area > 10000
          requirements << 'Étude d\'impact environnemental obligatoire'
        end
        
        if @project.project_type == 'industrial'
          requirements << 'Autorisation ICPE'
          requirements << 'Étude de sol obligatoire'
        end
        
        requirements
      end

      def safety_requirements
        [
          'Respect du code de la construction',
          'Normes incendie',
          'Accessibilité PMR',
          'Contrôles techniques obligatoires'
        ]
      end

      def accessibility_requirements
        [
          'Accessibilité PMR (Art. R111-19)',
          'Largeur des passages',
          'Rampes d\'accès conformes',
          'Sanitaires adaptés'
        ]
      end

      def identify_missing_documents
        required_docs = get_required_documents_for_project_type
        submitted_docs = @project.permits.includes(:documents).flat_map(&:documents).pluck(:document_type)
        
        required_docs - submitted_docs
      end

      def get_required_documents_for_project_type
        base_docs = [
          'plan_situation',
          'plan_masse',
          'plan_facades',
          'notice_descriptive',
          'photos_terrain'
        ]
        
        case @project.project_type
        when 'commercial'
          base_docs + ['etude_impact_commercial', 'plan_amenagement_paysager']
        when 'industrial'
          base_docs + ['etude_impact_environnemental', 'etude_dangers']
        else
          base_docs
        end
      end

      def check_permit_conditions_compliance
        conditions_status = {}
        
        @project.permits.includes(:permit_conditions).each do |permit|
          permit.permit_conditions.each do |condition|
            conditions_status[condition.id] = {
              description: condition.description,
              status: condition.status,
              compliance_rate: calculate_condition_compliance_rate(condition),
              due_date: condition.due_date,
              is_overdue: condition.due_date && condition.due_date < Date.current && condition.status != 'validated'
            }
          end
        end
        
        conditions_status
      end

      def calculate_condition_compliance_rate(condition)
        # Calcul simplifié du taux de conformité
        case condition.status
        when 'validated' then 100
        when 'in_progress' then 50
        when 'pending' then 0
        else 0
        end
      end
    end
  end
end