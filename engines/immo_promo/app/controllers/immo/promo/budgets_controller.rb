module Immo
  module Promo
    class BudgetsController < ApplicationController
      before_action :set_project
      before_action :set_budget, only: [:show, :edit, :update, :destroy, :approve, :reject, :duplicate]
      
      def index
        @budgets = @project.budgets.includes(:budget_lines)
                                  .order(:created_at)
        
        # Filtrage par statut
        if params[:status].present?
          @budgets = @budgets.where(status: params[:status])
        end
        
        # Calcul des totaux
        @total_approved_budget = @budgets.approved.sum(&:total_amount)
        @total_spent = @budgets.approved.sum(&:spent_amount)
        @budget_utilization = @total_approved_budget > 0 ? (@total_spent / @total_approved_budget * 100).round : 0
        
        @pagy, @budgets = pagy(@budgets) if respond_to?(:pagy)
      end

      def show
        @budget_lines = @budget.budget_lines.includes(:phase)
                                           .order(:category, :description)
        
        @budget_summary = calculate_budget_summary
        @variance_analysis = calculate_variance_analysis
        @spending_by_category = calculate_spending_by_category
      end

      def new
        @budget = @project.budgets.build
        @budget.budget_lines.build # Ajouter une ligne par défaut
      end

      def create
        @budget = @project.budgets.build(budget_params)
        
        if @budget.save
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      notice: 'Budget créé avec succès.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @budget.update(budget_params)
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      notice: 'Budget modifié avec succès.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @budget.can_be_deleted?
          @budget.destroy
          redirect_to immo_promo_engine.project_budgets_path(@project),
                      notice: 'Budget supprimé avec succès.'
        else
          redirect_to immo_promo_engine.project_budgets_path(@project),
                      alert: 'Impossible de supprimer ce budget car il contient des dépenses.'
        end
      end

      def approve
        if @budget.may_approve?
          @budget.approve!
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      notice: 'Budget approuvé avec succès.'
        else
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      alert: 'Impossible d\'approuver ce budget.'
        end
      end

      def reject
        if @budget.may_reject?
          @budget.reject!
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      notice: 'Budget rejeté.'
        else
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      alert: 'Impossible de rejeter ce budget.'
        end
      end

      def duplicate
        new_budget = @budget.duplicate_for_revision
        
        if new_budget.persisted?
          redirect_to immo_promo_engine.edit_project_budget_path(@project, new_budget),
                      notice: 'Budget dupliqué avec succès. Vous pouvez maintenant le modifier.'
        else
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      alert: 'Erreur lors de la duplication du budget.'
        end
      end

      private

      def set_project
        @project = current_user.accessible_projects.find(params[:project_id])
      end

      def set_budget
        @budget = @project.budgets.find(params[:id])
      end

      def budget_params
        params.require(:budget).permit(
          :name, :description, :status, :start_date, :end_date,
          :total_amount, :contingency_percentage, :notes,
          budget_lines_attributes: [
            :id, :category, :description, :quantity, :unit_price,
            :total_amount, :phase_id, :supplier, :notes, :_destroy
          ]
        )
      end

      def calculate_budget_summary
        {
          total_planned: @budget.total_amount || 0,
          total_spent: @budget.spent_amount || 0,
          total_committed: @budget.committed_amount || 0,
          remaining: @budget.remaining_amount || 0,
          contingency: @budget.contingency_amount || 0
        }
      end

      def calculate_variance_analysis
        @budget.budget_lines.map do |line|
          {
            line: line,
            planned: line.total_amount || 0,
            actual: line.actual_amount || 0,
            variance: (line.actual_amount || 0) - (line.total_amount || 0),
            variance_percentage: line.variance_percentage
          }
        end
      end

      def calculate_spending_by_category
        @budget.budget_lines.group(:category).sum(:actual_amount)
      end
    end
  end
end