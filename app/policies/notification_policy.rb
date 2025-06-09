class NotificationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && notification_belongs_to_user?
  end

  def mark_as_read?
    user.present? && notification_belongs_to_user?
  end

  def destroy?
    user.present? && notification_belongs_to_user?
  end

  def mark_all_as_read?
    user.present?
  end

  def bulk_mark_as_read?
    user.present?
  end

  def bulk_destroy?
    user.present?
  end

  def dropdown?
    user.present?
  end

  def urgent?
    user.present?
  end

  def stats?
    user.present?
  end

  # ImmoPromo specific permissions
  def immo_promo_notifications?
    user.present? && user.has_permission?('immo_promo:access')
  end

  def project_notifications?
    user.present? && user.has_permission?('immo_promo:access')
  end

  class Scope < Scope
    def resolve
      if user.present?
        scope.for_user(user)
      else
        scope.none
      end
    end

    # Scope for ImmoPromo notifications only
    def immo_promo_scope
      if user.present? && user.has_permission?('immo_promo:access')
        immo_promo_types = ['projects', 'stakeholders', 'permits', 'budgets', 'risks']
                          .flat_map { |cat| Notification.notification_types_by_category(cat) }
        scope.for_user(user).where(notification_type: immo_promo_types)
      else
        scope.none
      end
    end

    # Scope for notifications related to a specific project
    def project_scope(project)
      return scope.none unless user.present?
      
      # Check if user has access to the project
      return scope.none unless project && Pundit.policy(user, project).show?
      
      # Get notifications related to the project and its associated objects
      scope.for_user(user)
           .joins(:notifiable)
           .where(
             notifiable: [
               project,
               project.phases,
               project.tasks,
               project.stakeholders,
               project.permits,
               project.budgets,
               project.risks
             ]
           )
    end
  end

  private

  def notification_belongs_to_user?
    record.user == user
  end

  # Additional helper methods for specific notification types
  def can_access_document_notification?
    return true unless record.notifiable.is_a?(Document)
    
    Pundit.policy(user, record.notifiable).show?
  end

  def can_access_immo_promo_notification?
    return true unless record.immo_promo_related?
    
    user.has_permission?('immo_promo:access')
  end

  def can_access_project_notification?
    return true unless record.notifiable.respond_to?(:project)
    
    project = record.notifiable.project
    return true unless project
    
    Pundit.policy(user, project).show?
  end

  def can_access_space_notification?
    return true unless record.notifiable.is_a?(Space)
    
    Pundit.policy(user, record.notifiable).show?
  end

  def can_access_folder_notification?
    return true unless record.notifiable.is_a?(Folder)
    
    Pundit.policy(user, record.notifiable).show?
  end
end