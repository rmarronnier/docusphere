class DocumentPolicy < ApplicationPolicy
  def show?
    # Les utilisateurs peuvent voir les documents de leur organisation
    record.space.organization == user.organization
  end
  
  def create?
    # Les utilisateurs peuvent créer des documents dans les espaces de leur organisation
    user.present?
  end
  
  def update?
    # Les utilisateurs peuvent modifier leurs propres documents ou ceux de leur organisation s'ils ont la permission
    record.user == user || (record.space.organization == user.organization && user.admin?)
  end
  
  def destroy?
    # Seuls les propriétaires et les admins peuvent supprimer
    record.user == user || user.admin?
  end
  
  def download?
    show?
  end
  
  def share?
    show? && (record.user == user || user.admin?)
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Les utilisateurs ne voient que les documents de leur organisation
      scope.joins(:space).where(spaces: { organization_id: user.organization_id })
    end
  end
end