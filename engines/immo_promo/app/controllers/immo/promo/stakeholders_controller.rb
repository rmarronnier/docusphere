module Immo
  module Promo
    class StakeholdersController < ApplicationController
      before_action :set_project
      before_action :set_stakeholder, only: [:show, :edit, :update, :destroy, :approve, :reject]
      
      def index
        @stakeholders = @project.stakeholders.includes(:certifications, :contracts, :user)
                                           .order(:name)
        @pagy, @stakeholders = pagy(@stakeholders)
        
        # Filtrage par rôle
        if params[:role].present?
          @stakeholders = @stakeholders.where(role: params[:role])
        end
        
        # Filtrage par statut
        if params[:status].present?
          @stakeholders = @stakeholders.where(status: params[:status])
        end
      end

      def show
        @certifications = @stakeholder.certifications.order(:obtained_at)
        @contracts = @stakeholder.contracts.includes(:project).order(:start_date)
        @recent_activity = @stakeholder.time_logs.includes(:task).limit(10).order(created_at: :desc)
      end

      def new
        @stakeholder = @project.stakeholders.build
        @available_users = User.where.not(id: @project.stakeholders.pluck(:user_id))
      end

      def create
        @stakeholder = @project.stakeholders.build(stakeholder_params)
        
        if @stakeholder.save
          redirect_to immo_promo_engine.project_stakeholder_path(@project, @stakeholder),
                      notice: 'Intervenant ajouté avec succès.'
        else
          @available_users = User.where.not(id: @project.stakeholders.pluck(:user_id))
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @stakeholder.update(stakeholder_params)
          redirect_to immo_promo_engine.project_stakeholder_path(@project, @stakeholder),
                      notice: 'Intervenant modifié avec succès.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @stakeholder.can_be_deleted?
          @stakeholder.destroy
          redirect_to immo_promo_engine.project_stakeholders_path(@project),
                      notice: 'Intervenant supprimé avec succès.'
        else
          redirect_to immo_promo_engine.project_stakeholders_path(@project),
                      alert: 'Impossible de supprimer cet intervenant car il a des activités en cours.'
        end
      end

      def approve
        if @stakeholder.may_approve?
          @stakeholder.approve!
          redirect_to immo_promo_engine.project_stakeholder_path(@project, @stakeholder),
                      notice: 'Intervenant approuvé avec succès.'
        else
          redirect_to immo_promo_engine.project_stakeholder_path(@project, @stakeholder),
                      alert: 'Impossible d\'approuver cet intervenant.'
        end
      end

      def reject
        if @stakeholder.may_reject?
          @stakeholder.reject!
          redirect_to immo_promo_engine.project_stakeholder_path(@project, @stakeholder),
                      notice: 'Intervenant rejeté.'
        else
          redirect_to immo_promo_engine.project_stakeholder_path(@project, @stakeholder),
                      alert: 'Impossible de rejeter cet intervenant.'
        end
      end

      private

      def set_project
        @project = current_user.accessible_projects.find(params[:project_id])
      end

      def set_stakeholder
        @stakeholder = @project.stakeholders.find(params[:id])
      end

      def stakeholder_params
        params.require(:stakeholder).permit(
          :user_id, :name, :email, :phone, :address, :role, :qualification_level,
          :hourly_rate, :daily_rate, :company_name, :siret, :insurance_number,
          :status, :notes
        )
      end
    end
  end
end