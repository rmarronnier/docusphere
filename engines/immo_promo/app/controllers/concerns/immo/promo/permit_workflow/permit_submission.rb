module Immo
  module Promo
    module PermitWorkflow
      module PermitSubmission
        extend ActiveSupport::Concern

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

        private

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
end