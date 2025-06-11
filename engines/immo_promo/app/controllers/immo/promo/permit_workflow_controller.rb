module Immo
  module Promo
    class PermitWorkflowController < Immo::Promo::ApplicationController
      include PermitWorkflow::WorkflowManagement
      include PermitWorkflow::PermitSubmission
      include PermitWorkflow::ComplianceTracking
      include PermitWorkflow::DocumentGeneration
      
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




    end
  end
end