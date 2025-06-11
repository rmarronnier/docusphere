class UserProfilePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def activate?
    user == record.user
  end
end