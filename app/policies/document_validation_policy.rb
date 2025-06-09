class DocumentValidationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def approve?
    user.present? && record.validator == user && record.pending?
  end

  def reject?
    user.present? && record.validator == user && record.pending?
  end

  class Scope < Scope
    def resolve
      if user.present?
        scope.where(validator: user)
      else
        scope.none
      end
    end
  end
end