class SearchPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def suggestions?
    user.present?
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end