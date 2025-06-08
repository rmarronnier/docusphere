module Immo
  module Promo
    class PhasesController < ApplicationController
      before_action :set_project
      before_action :set_phase, only: [ :show, :edit, :update, :destroy, :complete ]

      def index
        @phases = policy_scope(@project.phases).order(:position)
      end

      def show
        authorize @phase
        @tasks = @phase.tasks.includes(:assigned_to, :stakeholder).order(:start_date)
        @dependencies = @phase.phase_dependencies.includes(:prerequisite_phase)
      end

      def new
        @phase = @project.phases.build
        @phase.position = @project.phases.maximum(:position).to_i + 1
        authorize @phase
      end

      def create
        @phase = @project.phases.build(phase_params)
        authorize @phase

        if @phase.save
          redirect_to immo_promo_engine.project_phase_path(@project, @phase), notice: 'Phase créée avec succès.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        authorize @phase
      end

      def update
        authorize @phase

        if @phase.update(phase_params)
          redirect_to immo_promo_engine.project_phase_path(@project, @phase), notice: 'Phase mise à jour avec succès.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @phase

        if @phase.destroy
          redirect_to immo_promo_engine.project_path(@project), notice: 'Phase supprimée avec succès.'
        else
          redirect_to immo_promo_engine.project_phase_path(@project, @phase), alert: 'Impossible de supprimer la phase.'
        end
      end

      def complete
        authorize @phase, :complete_phase?

        if @phase.can_start? && @phase.update(status: 'completed', actual_end_date: Time.current)
          redirect_to immo_promo_engine.project_phase_path(@project, @phase), notice: 'Phase marquée comme terminée.'
        else
          redirect_to immo_promo_engine.project_phase_path(@project, @phase), alert: 'Impossible de terminer la phase.'
        end
      end

      private

      def set_project
        @project = policy_scope(Immo::Promo::Project).find(params[:project_id])
      end

      def set_phase
        @phase = @project.phases.find(params[:id])
      end

      def phase_params
        params.require(:immo_promo_phase).permit(
          :name, :description, :phase_type, :position, :is_critical,
          :start_date, :end_date, :budget_cents, :notes, :responsible_user_id
        )
      end
    end
  end
end
