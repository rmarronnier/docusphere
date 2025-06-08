module Immo
  module Promo
    class TasksController < Immo::Promo::ApplicationController
      before_action :set_project_and_phase
      before_action :set_task, only: [ :show, :edit, :update, :destroy, :complete, :assign ]

      def index
        @tasks = policy_scope(@phase.tasks).includes(:assigned_to, :stakeholder)
        @tasks = @tasks.where(status: params[:status]) if params[:status].present?
        @tasks = @tasks.where(assigned_to: params[:user_id]) if params[:user_id].present?
      end

      def show
        authorize @task
        @time_logs = @task.time_logs.includes(:user).order(log_date: :desc)
        @dependencies = @task.task_dependencies.includes(:prerequisite_task)
      end

      def new
        @task = @phase.tasks.build
        authorize @task
      end

      def create
        @task = @phase.tasks.build(task_params)
        authorize @task

        if @task.save
          redirect_to immo_promo_engine.project_phase_task_path(@project, @phase, @task), notice: 'Tâche créée avec succès.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        authorize @task
      end

      def update
        authorize @task

        if @task.update(task_params)
          redirect_to immo_promo_engine.project_phase_task_path(@project, @phase, @task), notice: 'Tâche mise à jour avec succès.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @task

        if @task.destroy
          redirect_to immo_promo_engine.project_phase_path(@project, @phase), notice: 'Tâche supprimée avec succès.'
        else
          redirect_to immo_promo_engine.project_phase_task_path(@project, @phase, @task), alert: 'Impossible de supprimer la tâche.'
        end
      end

      def complete
        authorize @task, :complete_task?

        if @task.update(status: 'completed', actual_end_date: Time.current)
          redirect_to immo_promo_engine.project_phase_task_path(@project, @phase, @task), notice: 'Tâche marquée comme terminée.'
        else
          redirect_to immo_promo_engine.project_phase_task_path(@project, @phase, @task), alert: 'Impossible de terminer la tâche.'
        end
      end

      def assign
        authorize @task, :assign_task?

        if @task.update(assigned_to_id: params[:user_id])
          redirect_to immo_promo_engine.project_phase_task_path(@project, @phase, @task), notice: 'Tâche assignée avec succès.'
        else
          redirect_to immo_promo_engine.project_phase_task_path(@project, @phase, @task), alert: 'Impossible d\'assigner la tâche.'
        end
      end

      def my_tasks
        skip_authorization
        @tasks = policy_scope(Immo::Promo::Task).where(assigned_to: current_user)
                                                .includes(:phase, phase: :project)
                                                .order(:end_date)
        @overdue_tasks = @tasks.overdue
        @upcoming_tasks = @tasks.due_soon
      end

      private

      def set_project_and_phase
        @project = policy_scope(Immo::Promo::Project).find(params[:project_id])
        @phase = @project.phases.find(params[:phase_id])
      end

      def set_task
        @task = @phase.tasks.find(params[:id])
      end

      def task_params
        params.require(:immo_promo_task).permit(
          :name, :description, :task_type, :priority,
          :start_date, :end_date, :estimated_hours, :estimated_cost_cents,
          :notes, :assigned_to_id, :stakeholder_id
        )
      end
    end
  end
end
