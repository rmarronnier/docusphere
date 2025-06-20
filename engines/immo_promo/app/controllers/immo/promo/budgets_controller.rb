module Immo
  module Promo
    class BudgetsController < Immo::Promo::ApplicationController
      before_action :set_project
      before_action :set_budget, only: [:show, :edit, :update, :destroy, :approve, :reject, :duplicate]
      before_action :authorize_budget, only: [:show, :edit, :update, :destroy, :duplicate]
      
      def index
        authorize @project, :show?
        @budgets = policy_scope(@project.budgets).includes(:budget_lines)
                                                 .order(:created_at)
        
        # Filtrage par statut
        if params[:status].present?
          @budgets = @budgets.where(status: params[:status])
        end
        
        # Calcul des totaux
        @total_approved_budget = @budgets.approved.sum(&:total_amount)
        @total_spent = @budgets.approved.sum(&:spent_amount)
        @budget_utilization = @total_approved_budget > 0 ? (@total_spent / @total_approved_budget * 100).round : 0
        
        @budgets = @budgets.page(params[:page]).per(10)
        
        respond_to do |format|
          format.html # Show HTML view
          format.json { head :ok } # For testing
        end
      end

      def show
        @budget_lines = @budget.budget_lines.order(:category, :description)
        
        @budget_summary = calculate_budget_summary
        @variance_analysis = calculate_variance_analysis
        @spending_by_category = calculate_spending_by_category
        
        respond_to do |format|
          format.html # Show HTML view
          format.json { head :ok } # For testing
        end
      end

      def new
        @budget = @project.budgets.build
        authorize @budget
        @budget.budget_lines.build # Ajouter une ligne par défaut
        
        respond_to do |format|
          format.html # Show HTML view
          format.json { head :ok } # For testing
        end
      end

      def create
        @budget = @project.budgets.build(budget_params)
        authorize @budget
        
        if @budget.save
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      notice: 'Budget créé avec succès.'
        else
          respond_to do |format|
            format.html { render :new, status: :unprocessable_entity }
            format.json { head :unprocessable_entity }
          end
        end
      end

      def edit
        respond_to do |format|
          format.html # Show HTML view
          format.json { head :ok } # For testing
        end
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
        authorize @budget
        if @budget.may_approve?
          @budget.approve!(current_user)
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      notice: 'Budget approuvé avec succès.'
        else
          redirect_to immo_promo_engine.project_budget_path(@project, @budget),
                      alert: 'Impossible d\'approuver ce budget.'
        end
      end

      def reject
        authorize @budget
        if @budget.may_reject?
          @budget.reject!(current_user, params[:reason])
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
        permitted_attributes(@budget || Immo::Promo::Budget.new)
      end

      def calculate_budget_summary
        {
          total_planned: @budget.total_amount || Money.new(0, 'EUR'),
          total_spent: @budget.spent_amount || Money.new(0, 'EUR'),
          remaining: @budget.remaining_amount || Money.new(0, 'EUR'),
          percentage_spent: @budget.spending_percentage || 0
        }
      end

      def calculate_variance_analysis
        @budget.budget_lines.map do |line|
          {
            line: line,
            planned: line.planned_amount || Money.new(0),
            actual: line.actual_amount || Money.new(0),
            variance: (line.actual_amount || Money.new(0)) - (line.planned_amount || Money.new(0)),
            variance_percentage: line.spending_percentage
          }
        end
      end

      def calculate_spending_by_category
        @budget.budget_lines.group(:category).sum(:actual_amount_cents)
      end

      def authorize_budget
        authorize @budget
      end
    end
  end
end