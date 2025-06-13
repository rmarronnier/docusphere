class SearchPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def suggestions?
    user.present?
  end

  def advanced?
    user.present?
  end

  def permitted_attributes
    [:name, :is_favorite, query_params: {}]
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end