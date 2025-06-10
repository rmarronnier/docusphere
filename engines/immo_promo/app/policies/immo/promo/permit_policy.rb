module Immo
  module Promo
    class PermitPolicy < ApplicationPolicy
      class Scope < Scope
        def resolve
          if user.admin? || user.super_admin?
            scope.all
          else
            scope.joins(:project).where(immo_promo_projects: { organization: user.organization })
          end
        end
      end

      def index?
        user.can_access_immo_promo?
      end

      def show?
        user.can_manage_project?(record.project)
      end

      def create?
        user.can_manage_project?(record.project)
      end

      def update?
        user.can_manage_project?(record.project)
      end

      def destroy?
        user.can_manage_project?(record.project) && record.draft?
      end

      def submit_for_approval?
        user.can_manage_project?(record.project) && record.draft?
      end

      def approve?
        user.admin? || user.super_admin?
      end

      def reject?
        user.admin? || user.super_admin?
      end

      def permitted_attributes
        [:permit_type, :permit_number, :status, :application_date, :submitted_date, 
         :approval_date, :approved_date, :expiry_date, :issuing_authority, 
         :conditions, :notes, :title, :reference, :fee_amount_cents, 
         :description, :name, :cost, :expected_approval_date, :workflow_status, 
         documents: []]
      end
    end
  end
end