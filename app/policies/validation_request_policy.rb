class ValidationRequestPolicy < ApplicationPolicy
  def show?
    user.present? && (
      record.requester == user ||
      record.document_validations.exists?(validator: user) ||
      user.admin? ||
      user.super_admin?
    )
  end

  def create?
    user.present? && record.validatable.can_request_validation?(user)
  end

  def my_requests?
    user.present?
  end

  def permitted_attributes
    [:min_validations, :description, :due_date]
  end

  class Scope < Scope
    def resolve
      if user.present?
        scope.for_requester(user)
      else
        scope.none
      end
    end
  end
end