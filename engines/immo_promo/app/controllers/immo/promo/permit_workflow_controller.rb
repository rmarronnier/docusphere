module Immo
  module Promo
    class PermitWorkflowController < ApplicationController
      before_action :set_project
      before_action :authorize_permit_access

      def dashboard
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

      def timeline_tracker
        @permit_tracker = PermitTrackerService.new(@project, current_user)
        @timeline_data = @permit_tracker.generate_permit_timeline
        @processing_times = @permit_tracker.calculate_processing_times
        @deadlines = upcoming_permit_deadlines
        @milestones = permit_milestones
      end

      def critical_path
        @permit_tracker = PermitTrackerService.new(@project, current_user)
        @critical_permits = @permit_tracker.critical_permits_status
        @dependencies = calculate_permit_dependencies
        @blocking_permits = identify_blocking_permits
        @construction_readiness = assess_construction_readiness
      end

      def submit_permit
        @permit = @project.permits.find(params[:permit_id])
        
        if @permit.can_be_submitted?
          result = submit_permit_application(@permit)
          
          if result[:success]
            flash[:success] = "Demande de #{@permit.permit_type.humanize} soumise avec succès"
            @permit.update(
              status: 'submitted',
              submission_date: Date.current,
              submitted_by: current_user
            )
          else
            flash[:error] = result[:error]
          end
        else
          flash[:error] = "Ce permis ne peut pas être soumis dans son état actuel"
        end
        
        redirect_to immo_promo_engine.project_permit_workflow_dashboard_path(@project)
      end

      def track_response
        @permit = @project.permits.find(params[:permit_id])
        
        # Vérifier automatiquement le statut auprès de l'administration
        response_data = check_permit_status_with_administration(@permit)
        
        if response_data[:status_changed]
          @permit.update(
            status: response_data[:new_status],
            response_date: response_data[:response_date],
            administration_reference: response_data[:reference]
          )
          
          flash[:success] = "Statut du permis mis à jour : #{response_data[:new_status].humanize}"
        else
          flash[:info] = "Aucune mise à jour disponible pour ce permis"
        end
        
        redirect_back(fallback_location: immo_promo_engine.project_permit_workflow_dashboard_path(@project))
      end

      def extend_permit
        @permit = @project.permits.find(params[:permit_id])
        
        if @permit.can_be_extended?
          extension_data = {
            permit_id: @permit.id,
            current_expiry: @permit.expiry_date,
            requested_extension: params[:extension_months]&.to_i || 12,
            justification: params[:justification]
          }
          
          result = request_permit_extension(@permit, extension_data)
          
          if result[:success]
            @permit.update(
              extension_status: 'requested',
              extension_requested_at: Date.current,
              extension_justification: params[:justification]
            )
            flash[:success] = "Demande de prolongation soumise"
          else
            flash[:error] = result[:error]
          end
        else
          flash[:error] = "Ce permis ne peut pas être prolongé"
        end
        
        redirect_back(fallback_location: immo_promo_engine.project_permit_workflow_dashboard_path(@project))
      end

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

      def generate_submission_package
        @permit = @project.permits.find(params[:permit_id])
        
        package_data = compile_submission_package(@permit)
        
        respond_to do |format|
          format.pdf do
            render pdf: "dossier_#{@permit.permit_type}_#{@project.reference_number}",
                   layout: 'pdf',
                   template: 'immo/promo/permit_workflow/submission_package_pdf',
                   locals: { package_data: package_data }
          end
          format.zip do
            zip_file = generate_submission_zip(@permit, package_data)
            send_file zip_file, filename: "dossier_#{@permit.permit_type}_#{@project.reference_number}.zip"
          end
        end
      end

      def alert_administration
        @permit = @project.permits.find(params[:permit_id])
        alert_type = params[:alert_type]
        
        case alert_type
        when 'delay_inquiry'
          result = send_delay_inquiry(@permit)
          message = "Demande de suivi envoyée à l'administration"
        when 'urgent_request'
          result = send_urgent_request(@permit, params[:urgency_justification])
          message = "Demande urgente transmise"
        when 'appeal_request'
          result = initiate_appeal_process(@permit, params[:appeal_grounds])
          message = "Procédure de recours initiée"
        else
          result = { success: false, error: "Type d'alerte non reconnu" }
        end
        
        if result[:success]
          flash[:success] = message
          # Log l'action pour suivi
          log_permit_action(@permit, alert_type, current_user)
        else
          flash[:error] = result[:error]
        end
        
        redirect_back(fallback_location: immo_promo_engine.project_permit_workflow_dashboard_path(@project))
      end

      def export_report
        @permit_tracker = PermitTrackerService.new(@project, current_user)
        @report_data = @permit_tracker.generate_permit_report
        
        respond_to do |format|
          format.pdf do
            render pdf: "rapport_permis_#{@project.reference_number}",
                   layout: 'pdf',
                   template: 'immo/promo/permit_workflow/report_pdf'
          end
          format.xlsx do
            render xlsx: 'report_xlsx',
                   filename: "rapport_permis_#{@project.reference_number}.xlsx"
          end
        end
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
            reference: @project.reference_number,
            type: @project.project_type
          },
          permit_status: @permit_status,
          critical_permits: @critical_permits,
          compliance: @compliance_check,
          bottlenecks: @bottlenecks,
          next_actions: @next_actions
        }
      end

      def generate_workflow_for_project_type(project_type)
        base_workflow = [
          {
            step: 1,
            name: 'Étude de faisabilité',
            description: 'Analyse réglementaire et contraintes',
            permits_required: ['feasibility_study'],
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
            permits_required: ['technical_authorizations'],
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

      def residential_specific_steps
        [
          {
            step: 4,
            name: 'Conformité accessibilité',
            description: 'Validation normes PMR',
            permits_required: ['accessibility_compliance'],
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
            permits_required: ['commercial_authorization'],
            estimated_duration: '3-6 mois'
          },
          {
            step: 5,
            name: 'Sécurité incendie',
            description: 'Validation ERP',
            permits_required: ['fire_safety'],
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
            permits_required: ['environmental_impact', 'icpe'],
            estimated_duration: '6-12 mois'
          },
          {
            step: 5,
            name: 'Autorisations DREAL',
            description: 'Exploitation installations classées',
            permits_required: ['dreal_authorization'],
            estimated_duration: '3-6 mois'
          }
        ]
      end

      def determine_current_workflow_step
        workflow_steps = generate_workflow_for_project_type(@project.project_type)
        
        workflow_steps.each_with_index do |step, index|
          required_permits = step[:permits_required]
          completed_permits = @project.permits.where(permit_type: required_permits, status: 'approved').count
          
          return index + 1 if completed_permits < required_permits.count
        end
        
        workflow_steps.count + 1 # Toutes les étapes terminées
      end

      def calculate_completed_steps
        current_step = determine_current_workflow_step
        current_step - 1
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

      def identify_missing_documents
        required_docs = get_required_documents_for_project
        existing_docs = @project.documents.pluck(:document_type)
        
        required_docs.reject { |doc| existing_docs.include?(doc) }
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

      def upcoming_permit_deadlines
        deadlines = []
        
        # Délais de soumission
        @project.permits.draft.each do |permit|
          deadline = calculate_optimal_submission_date(permit)
          deadlines << {
            type: 'submission',
            permit: permit,
            deadline: deadline,
            urgency: calculate_deadline_urgency(deadline),
            description: "Soumission optimale pour #{permit.permit_type.humanize}"
          }
        end
        
        # Délais d'expiration
        @project.permits.approved.each do |permit|
          next unless permit.expiry_date
          
          deadlines << {
            type: 'expiry',
            permit: permit,
            deadline: permit.expiry_date,
            urgency: calculate_deadline_urgency(permit.expiry_date),
            description: "Expiration #{permit.permit_type.humanize}"
          }
        end
        
        deadlines.sort_by { |d| d[:deadline] }
      end

      def calculate_optimal_submission_date(permit)
        # Calcule la date optimale de soumission basée sur les dépendances
        case permit.permit_type
        when 'construction'
          # Doit être soumis après l'approbation de l'urbanisme
          urban_permit = @project.permits.find_by(permit_type: 'urban_planning')
          if urban_permit&.approved?
            Date.current + 1.week
          else
            Date.current + 3.months # Estimation si urbanisme en cours
          end
        else
          Date.current + 2.weeks
        end
      end

      def calculate_deadline_urgency(deadline)
        days_remaining = (deadline - Date.current).to_i
        
        case days_remaining
        when ..7
          'critical'
        when 8..30
          'high'
        when 31..60
          'medium'
        else
          'low'
        end
      end

      def permit_milestones
        milestones = []
        
        @project.permits.includes(:permit_conditions).each do |permit|
          # Jalons de soumission
          if permit.submission_date
            milestones << {
              date: permit.submission_date,
              type: 'submission',
              permit: permit,
              title: "Soumission #{permit.permit_type.humanize}",
              status: 'completed'
            }
          end
          
          # Jalons de réponse
          if permit.response_date
            milestones << {
              date: permit.response_date,
              type: 'response',
              permit: permit,
              title: "Réponse #{permit.permit_type.humanize}",
              status: permit.status == 'approved' ? 'success' : 'warning'
            }
          end
          
          # Jalons de conditions
          permit.permit_conditions.validated.each do |condition|
            milestones << {
              date: condition.validated_at,
              type: 'condition_validated',
              permit: permit,
              condition: condition,
              title: "Condition validée: #{condition.description}",
              status: 'completed'
            }
          end
        end
        
        milestones.sort_by { |m| m[:date] }.reverse
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
          %w[urban_planning construction technical_authorizations accessibility_compliance]
        when 'commercial'
          %w[urban_planning construction technical_authorizations commercial_authorization fire_safety]
        when 'industrial'
          %w[urban_planning construction technical_authorizations environmental_impact icpe dreal_authorization]
        else
          %w[urban_planning construction technical_authorizations]
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

      # Méthodes d'intégration avec l'administration (simulées)
      def submit_permit_application(permit)
        # Simule la soumission électronique
        {
          success: true,
          reference: "REF-#{permit.id}-#{Time.current.to_i}",
          submission_date: Date.current
        }
      end

      def check_permit_status_with_administration(permit)
        # Simule la vérification du statut
        {
          status_changed: false,
          current_status: permit.status
        }
      end

      def request_permit_extension(permit, extension_data)
        # Simule la demande de prolongation
        {
          success: true,
          reference: "EXT-#{permit.id}-#{Time.current.to_i}"
        }
      end

      def validate_permit_condition(condition, validation_data)
        # Valide une condition de permis
        {
          valid: validation_data.present?,
          errors: validation_data.present? ? [] : ['Données de validation manquantes']
        }
      end

      def compile_submission_package(permit)
        # Compile le dossier de soumission
        {
          permit: permit,
          required_documents: get_required_documents_for_permit(permit),
          forms: get_required_forms_for_permit(permit),
          studies: get_required_studies_for_permit(permit)
        }
      end

      def get_required_documents_for_permit(permit)
        case permit.permit_type
        when 'construction'
          %w[plans_masse plans_facades plans_coupes notice_architecturale]
        when 'urban_planning'
          %w[plan_situation plan_masse notice_urbanisme]
        else
          %w[plans_masse]
        end
      end

      def get_required_forms_for_permit(permit)
        case permit.permit_type
        when 'construction'
          %w[cerfa_13406 attestation_rt2012]
        when 'urban_planning'
          %w[cerfa_13703]
        else
          []
        end
      end

      def get_required_studies_for_permit(permit)
        case permit.permit_type
        when 'construction'
          %w[etude_sol etude_thermique]
        when 'environmental_impact'
          %w[etude_impact notice_incidences]
        else
          []
        end
      end

      def generate_submission_zip(permit, package_data)
        # Génère un fichier ZIP avec tous les documents
        # Implémentation simulée
        temp_file = Tempfile.new(['submission', '.zip'])
        temp_file.path
      end

      def send_delay_inquiry(permit)
        # Envoie une demande de suivi de délai
        { success: true, reference: "DELAY-#{permit.id}" }
      end

      def send_urgent_request(permit, justification)
        # Envoie une demande urgente
        { success: true, reference: "URGENT-#{permit.id}" }
      end

      def initiate_appeal_process(permit, grounds)
        # Initie une procédure de recours
        { success: true, reference: "APPEAL-#{permit.id}" }
      end

      def log_permit_action(permit, action_type, user)
        # Log les actions sur les permis pour audit
        Rails.logger.info "PERMIT_ACTION: #{action_type} on permit #{permit.id} by user #{user.id}"
      end
    end
  end
end