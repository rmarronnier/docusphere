module Immo
  module Promo
    class BudgetLinesController < Immo::Promo::ApplicationController
      before_action :set_project
      before_action :set_budget
      before_action :set_budget_line, only: [:show, :edit, :update, :destroy]
      
      def index
        authorize @project, :show?
        
        @budget_lines = @budget.budget_lines.includes(:phase)
                                           .order(:category, :description)
        
        # Filtrage par catégorie
        if params[:category].present?
          @budget_lines = @budget_lines.where(category: params[:category])
        end
        
        @categories = @budget.budget_lines.distinct.pluck(:category).compact
        
        @pagy, @budget_lines = pagy(@budget_lines) if respond_to?(:pagy)
      end

      def show
        authorize @project, :show?
        # @expense_history = @budget_line.expenses.order(created_at: :desc).limit(10)
        @variance_trend = calculate_variance_trend
      end

      def new
        authorize @project, :update?
        @budget_line = @budget.budget_lines.build
      end

      def create
        authorize @project, :update?
        @budget_line = @budget.budget_lines.build(budget_line_params)
        
        if @budget_line.save
          redirect_to immo_promo_engine.project_budget_budget_lines_path(@project, @budget),
                      notice: 'Ligne budgétaire ajoutée avec succès.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        authorize @project, :update?
      end

      def update
        authorize @project, :update?
        if @budget_line.update(budget_line_params)
          redirect_to immo_promo_engine.project_budget_budget_line_path(@project, @budget, @budget_line),
                      notice: 'Ligne budgétaire modifiée avec succès.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @project, :update?
        if @budget_line.can_be_deleted?
          @budget_line.destroy
          redirect_to immo_promo_engine.project_budget_budget_lines_path(@project, @budget),
                      notice: 'Ligne budgétaire supprimée avec succès.'
        else
          redirect_to immo_promo_engine.project_budget_budget_lines_path(@project, @budget),
                      alert: 'Impossible de supprimer cette ligne car elle contient des dépenses.'
        end
      end

      private

      def set_project
        @project = policy_scope(Immo::Promo::Project).find(params[:project_id])
      end

      def set_budget
        @budget = @project.budgets.find(params[:budget_id])
      end

      def set_budget_line
        @budget_line = @budget.budget_lines.find(params[:id])
      end

      def budget_line_params
        permitted_attributes(@budget_line || Immo::Promo::BudgetLine.new)
      end

      def calculate_variance_trend
        # Calculer l'évolution de la variance sur les 6 derniers mois
        months = 6.times.map { |i| i.months.ago.beginning_of_month }
        
        months.map do |month|
          planned_amount = @budget_line.planned_amount_cents || 0
          actual_amount = @budget_line.actual_amount_cents || 0
          
          {
            month: month,
            planned: planned_amount,
            actual: actual_amount,
            variance: actual_amount - planned_amount
          }
        end.reverse
      end
    end
  end
end