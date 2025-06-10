class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def permitted_attributes
    []
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  private

  def user_is_admin?
    user&.admin? || user&.super_admin?
  end

  def user_is_super_admin?
    user&.super_admin?
  end

  def same_organization?
    return false unless user&.organization && record.respond_to?(:organization)
    user.organization == record.organization
  end

  def same_organization_or_admin?
    user_is_admin? || same_organization?
  end

  def user_has_permission?(permission)
    user&.has_permission?(permission)
  end

  def user_can_read?(resource)
    return true if user_is_admin?
    return false unless resource.respond_to?(:readable_by?)
    resource.readable_by?(user)
  end

  def user_can_write?(resource)
    return true if user_is_admin?
    return false unless resource.respond_to?(:writable_by?)
    resource.writable_by?(user)
  end
end