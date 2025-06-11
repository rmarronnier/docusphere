module Immo
  module Promo
    class Budget < ApplicationRecord
      self.table_name = 'immo_promo_budgets'

      include Validatable
      audited

      belongs_to :project, class_name: 'Immo::Promo::Project'
      has_many :budget_lines, class_name: 'Immo::Promo::BudgetLine', dependent: :destroy

      validates :name, presence: true
      validates :budget_type, inclusion: { in: %w[initial revised final] }
      validates :version, presence: true, uniqueness: { scope: :project_id }

      monetize :total_amount_cents
      monetize :spent_amount_cents, allow_nil: true

      # Declare attribute type for enum
      attribute :budget_type, :string

      enum budget_type: {
        initial: 'initial',
        revised: 'revised',
        final: 'final'
      }

      scope :current, -> { where(is_current: true) }
      scope :by_type, ->(type) { where(budget_type: type) }
      scope :approved, -> { where(status: 'approved') }

      def remaining_amount
        total_amount - (spent_amount || Money.new(0))
      end

      def spending_percentage
        return 0 unless total_amount.cents > 0
        ((spent_amount || Money.new(0)) / total_amount * 100).round(2)
      end

      def is_over_budget?
        spent_amount && spent_amount > total_amount
      end

      def variance
        (spent_amount || Money.new(0)) - total_amount
      end

      def total_budget_lines_amount
        budget_lines.sum(&:amount)
      end

      def budget_line_by_category(category)
        budget_lines.where(category: category)
      end
      
      # Méthodes pour les workflows utilisant Validatable
      def can_be_deleted?
        budget_lines.empty? && !validated?
      end
      
      # Utilise le système Validatable pour l'approbation
      def approved?
        validated?
      end
      
      def may_approve?
        !validation_pending? && !validated?
      end
      
      def approve!(user)
        if validation_pending?
          # Si une validation est en cours, l'approuver
          validate_by!(user, approved: true)
        else
          # Sinon créer une auto-validation
          request_validation(requester: user, validators: [user])
          validate_by!(user, approved: true)
        end
        update!(status: 'approved', approved_date: Date.current)
      end
      
      def may_reject?
        validation_pending? || validated?
      end
      
      def reject!(user, reason = nil)
        if validation_pending?
          validate_by!(user, approved: false, comment: reason)
        end
        update!(status: 'rejected')
      end
      
      def duplicate_for_revision
        new_budget = dup
        new_budget.version = (version.to_i + 1).to_s
        new_budget.status = 'draft'
        new_budget.approved_date = nil
        new_budget.approved_by_id = nil
        new_budget.save!
        new_budget
      end
    end
  end
end
