module Immo
  module Promo
    class CoordinationController < Immo::Promo::ApplicationController
      before_action :set_project
      before_action :authorize_coordination_access

      def dashboard
        @coordinator = StakeholderCoordinatorService.new(@project, current_user)
        @coordination_data = @coordinator.coordinate_interventions
        @certifications_status = @coordinator.check_certifications
        @coordination_report = @coordinator.generate_coordination_report
        
        respond_to do |format|
          format.html
          format.json { render json: coordination_dashboard_data }
        end
      end

      def interventions
        @coordinator = StakeholderCoordinatorService.new(@project, current_user)
        @coordination_data = @coordinator.coordinate_interventions
        
        @current_interventions = @coordination_data[:current_interventions]
        @upcoming_interventions = @coordination_data[:upcoming_interventions]
        @conflicts = @coordination_data[:conflicts]
        @recommendations = @coordination_data[:recommendations]
      end

      def certifications
        @coordinator = StakeholderCoordinatorService.new(@project, current_user)
        @certifications_status = @coordinator.check_certifications
        
        @critical_stakeholders = @certifications_status.select { |cs| cs[:status] == 'critical' }
        @warning_stakeholders = @certifications_status.select { |cs| cs[:status] == 'warning' }
        @valid_stakeholders = @certifications_status.select { |cs| cs[:status] == 'valid' }
      end

      def performance
        @coordinator = StakeholderCoordinatorService.new(@project, current_user)
        @coordination_report = @coordinator.generate_coordination_report
        @performance_data = @coordination_report[:stakeholder_performance]
        
        @top_performers = @performance_data.sort_by { |sp| -sp[:performance_score] }.first(5)
        @poor_performers = @performance_data.select { |sp| sp[:performance_score] < 70 }
      end

      def timeline
        @coordinator = StakeholderCoordinatorService.new(@project, current_user)
        @coordination_report = @coordinator.generate_coordination_report
        @timeline_data = @coordination_report[:intervention_timeline]
        
        # Grouper par phase pour une vue organisée
        @timeline_by_phase = @timeline_data.group_by { |item| item[:phase] }
      end

      def conflicts_resolution
        @coordinator = StakeholderCoordinatorService.new(@project, current_user)
        @coordination_data = @coordinator.coordinate_interventions
        
        @conflicts = @coordination_data[:conflicts]
        @recommendations = @coordination_data[:recommendations]
        
        if request.post?
          handle_conflict_resolution
        end
      end

      def assign_stakeholder
        @task = @project.tasks.find(params[:task_id])
        @stakeholder = @project.stakeholders.find(params[:stakeholder_id])
        
        if @task.update(assigned_to: @stakeholder)
          flash[:success] = "Tâche réaffectée avec succès à #{@stakeholder.name}"
          redirect_to immo_promo_engine.project_coordination_conflicts_resolution_path(@project)
        else
          flash[:error] = "Erreur lors de la réaffectation"
          redirect_back(fallback_location: immo_promo_engine.project_coordination_dashboard_path(@project))
        end
      end

      def send_coordination_alert
        @coordinator = StakeholderCoordinatorService.new(@project, current_user)
        
        stakeholder_ids = params[:stakeholder_ids] || []
        message = params[:message]
        alert_type = params[:alert_type]
        
        if stakeholder_ids.any? && message.present?
          notifications = send_alerts_to_stakeholders(stakeholder_ids, message, alert_type)
          flash[:success] = "Alertes envoyées à #{notifications.count} intervenants"
        else
          flash[:error] = "Veuillez sélectionner des intervenants et saisir un message"
        end
        
        redirect_back(fallback_location: immo_promo_engine.project_coordination_dashboard_path(@project))
      end

      def export_report
        @coordinator = StakeholderCoordinatorService.new(@project, current_user)
        @coordination_report = @coordinator.generate_coordination_report
        
        respond_to do |format|
          format.pdf do
            render pdf: "rapport_coordination_#{@project.reference_number}",
                   layout: 'pdf',
                   template: 'immo/promo/coordination/report_pdf'
          end
          format.xlsx do
            render xlsx: 'report_xlsx',
                   filename: "rapport_coordination_#{@project.reference_number}.xlsx"
          end
        end
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def authorize_coordination_access
        authorize @project, :coordinate?
      end

      def coordination_dashboard_data
        {
          project: {
            id: @project.id,
            name: @project.name,
            reference: @project.reference_number
          },
          coordination: @coordination_data,
          certifications: @certifications_status,
          report: @coordination_report
        }
      end

      def handle_conflict_resolution
        resolution_actions = params[:resolution_actions] || {}
        
        resolution_actions.each do |conflict_id, action|
          case action[:type]
          when 'reassign_task'
            task = @project.tasks.find(action[:task_id])
            new_assignee = @project.stakeholders.find(action[:new_assignee_id])
            
            if task.update(assigned_to: new_assignee)
              flash[:success] = "Tâche #{task.name} réaffectée à #{new_assignee.name}"
            end
          when 'adjust_schedule'
            task = @project.tasks.find(action[:task_id])
            new_start_date = Date.parse(action[:new_start_date])
            new_due_date = Date.parse(action[:new_due_date])
            
            if task.update(start_date: new_start_date, due_date: new_due_date)
              flash[:success] = "Planning de #{task.name} ajusté"
            end
          end
        end
      end

      def send_alerts_to_stakeholders(stakeholder_ids, message, alert_type)
        notifications = []
        
        stakeholder_ids.each do |stakeholder_id|
          stakeholder = @project.stakeholders.find(stakeholder_id)
          
          # Créer la notification
          notification_data = {
            recipient: stakeholder,
            sender: current_user,
            project: @project,
            title: "Alerte de coordination - #{alert_type}",
            message: message,
            alert_type: alert_type,
            sent_at: Time.current
          }
          
          # Dans un vrai système, on utiliserait un service de notification
          # NotificationService.send_coordination_alert(notification_data)
          
          notifications << notification_data
        end
        
        notifications
      end
    end
  end
end