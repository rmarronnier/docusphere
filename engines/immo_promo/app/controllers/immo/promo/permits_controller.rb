module Immo
  module Promo
    class PermitsController < Immo::Promo::ApplicationController
      before_action :set_project
      before_action :set_permit, only: [:show, :edit, :update, :destroy, :submit_for_approval, :approve, :reject]
      
      def index
        @permits = policy_scope(@project.permits).includes(:permit_conditions)
                                                .order(:submitted_date)
        
        # Filtrage par statut
        if params[:status].present?
          @permits = @permits.where(status: params[:status])
        end
        
        # Filtrage par type
        if params[:permit_type].present?
          @permits = @permits.where(permit_type: params[:permit_type])
        end
        
        @pagy, @permits = pagy(@permits) if respond_to?(:pagy)
      end

      def show
        @conditions = @permit.conditions.order(:deadline)
        @pending_conditions = @conditions.where(status: 'pending')
        @timeline_events = permit_timeline_events
      end

      def new
        @permit = @project.permits.build
        @permit.conditions.build # Ajouter une condition par défaut
      end

      def create
        @permit = @project.permits.build(permit_params)
        
        if @permit.save
          redirect_to immo_promo_engine.project_permit_path(@project, @permit),
                      notice: 'Permis créé avec succès.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @permit.update(permit_params)
          redirect_to immo_promo_engine.project_permit_path(@project, @permit),
                      notice: 'Permis modifié avec succès.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @permit.can_be_deleted?
          @permit.destroy
          redirect_to immo_promo_engine.project_permits_path(@project),
                      notice: 'Permis supprimé avec succès.'
        else
          redirect_to immo_promo_engine.project_permits_path(@project),
                      alert: 'Impossible de supprimer ce permis.'
        end
      end

      def submit_for_approval
        if @permit.may_submit?
          @permit.submit!
          
          # Programmer les rappels pour les échéances
          schedule_deadline_reminders
          
          redirect_to immo_promo_engine.project_permit_path(@project, @permit),
                      notice: 'Permis soumis pour approbation.'
        else
          redirect_to immo_promo_engine.project_permit_path(@project, @permit),
                      alert: 'Impossible de soumettre ce permis.'
        end
      end

      def approve
        if @permit.may_approve?
          @permit.approve!
          redirect_to immo_promo_engine.project_permit_path(@project, @permit),
                      notice: 'Permis approuvé avec succès.'
        else
          redirect_to immo_promo_engine.project_permit_path(@project, @permit),
                      alert: 'Impossible d\'approuver ce permis.'
        end
      end

      def reject
        if @permit.may_reject?
          @permit.reject!
          redirect_to immo_promo_engine.project_permit_path(@project, @permit),
                      notice: 'Permis rejeté.'
        else
          redirect_to immo_promo_engine.project_permit_path(@project, @permit),
                      alert: 'Impossible de rejeter ce permis.'
        end
      end

      private

      def set_project
        @project = current_user.accessible_projects.find(params[:project_id])
      end

      def set_permit
        @permit = @project.permits.find(params[:id])
      end

      def permit_params
        params.require(:permit).permit(
          :name, :permit_type, :description, :issuing_authority,
          :submission_date, :expected_approval_date, :approval_date,
          :expiry_date, :cost, :status, :reference_number, :notes,
          conditions_attributes: [
            :id, :description, :deadline, :status, :completion_date, 
            :responsible_authority, :notes, :_destroy
          ]
        )
      end

      def schedule_deadline_reminders
        @permit.conditions.pending.each do |condition|
          next unless condition.deadline.present?
          
          # Programmer rappel 30 jours avant
          reminder_date = condition.deadline - 30.days
          if reminder_date > Date.current
            PermitDeadlineReminderJob.perform_at(reminder_date, condition.id)
          end
          
          # Programmer rappel 7 jours avant
          reminder_date = condition.deadline - 7.days
          if reminder_date > Date.current
            PermitDeadlineReminderJob.perform_at(reminder_date, condition.id)
          end
        end
      end

      def permit_timeline_events
        events = []
        
        # Ajout des événements du permis
        events << {
          date: @permit.submitted_date,
          type: 'submission',
          title: 'Soumission du permis',
          description: "Permis soumis à #{@permit.issuing_authority}",
          icon: 'upload'
        }
        
        if @permit.approval_date.present?
          events << {
            date: @permit.approval_date,
            type: 'approval',
            title: 'Permis approuvé',
            description: 'Le permis a été approuvé par l\'autorité compétente',
            icon: 'check_circle'
          }
        end
        
        # Ajout des événements des conditions
        @permit.conditions.each do |condition|
          if condition.completion_date.present?
            events << {
              date: condition.completion_date,
              type: 'condition_completed',
              title: 'Condition remplie',
              description: condition.description,
              icon: 'flag'
            }
          elsif condition.deadline.present?
            events << {
              date: condition.deadline,
              type: 'condition_deadline',
              title: 'Échéance condition',
              description: condition.description,
              icon: 'exclamation_triangle',
              warning: condition.deadline < Date.current
            }
          end
        end
        
        events.sort_by { |event| event[:date] }
      end
    end
  end
end