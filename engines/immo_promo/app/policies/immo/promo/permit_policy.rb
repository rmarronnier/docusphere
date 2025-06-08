module Immo
  module Promo
    class PermitPolicy < ApplicationPolicy
      class Scope < Scope
        def resolve
          if user.admin? || user.super_admin?
            scope.all
          else
            scope.joins(:project).where(projects: { organization: user.organization })
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
    end
  end
end