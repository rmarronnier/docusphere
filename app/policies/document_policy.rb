class DocumentPolicy < ApplicationPolicy
  def show?
    # Admin can see all documents
    return true if user.admin? || user.super_admin?
    
    # Check if document is shared with the user
    if record.document_shares.active.where(shared_with: user).exists?
      return true
    end
    
    # Si le document est lié à un espace
    if record.space.present?
      record.space.organization == user.organization
    # Si le document est lié à un objet documentable
    elsif record.documentable.present? && record.documentable.respond_to?(:can_read_documents?)
      record.documentable.can_read_documents?(user)
    else
      false
    end
  end

  def create?
    user.present?
  end

  def update?
    # Les utilisateurs peuvent modifier leurs propres documents
    return true if record.uploaded_by == user

    # Les admins peuvent modifier les documents de leur organisation
    if record.space.present?
      record.space.organization == user.organization && user.admin?
    elsif record.documentable.present? && record.documentable.respond_to?(:can_manage_documents?)
      record.documentable.can_manage_documents?(user)
    else
      user.admin?
    end
  end

  def destroy?
    # Les propriétaires et les admins peuvent supprimer
    record.uploaded_by == user || user.admin? ||
      (record.documentable.present? && record.documentable.respond_to?(:can_manage_documents?) &&
       record.documentable.can_manage_documents?(user))
  end

  def download?
    show?
  end

  def preview?
    show?
  end

  def share?
    show? && (record.uploaded_by == user || user.admin? ||
      (record.documentable.present? && record.documentable.respond_to?(:can_manage_documents?) &&
       record.documentable.can_manage_documents?(user)))
  end

  def force_unlock?
    user.admin? || user.super_admin?
  end

  def request_validation?
    record.uploaded_by == user ||
      (record.documentable.present? && record.documentable.respond_to?(:can_manage_documents?) &&
       record.documentable.can_manage_documents?(user))
  end

  def restore_version?
    update?
  end

  def annotate?
    # Users can annotate documents they can update
    update?
  end

  def export?
    # Users can export documents they can view
    show?
  end

  def permitted_attributes
    base_attributes = [:title, :description, :document_type, :status, :is_template,
                      :external_id, :expires_at, :is_public, :document_category,
                      :file, :space_id, :folder_id, :documentable_id, :documentable_type,
                      metadata: {}]

    if user.admin? || user.super_admin?
      base_attributes + [:processing_status, :virus_scan_status, :ai_category,
                         :ai_confidence, ai_entities: {}, processing_metadata: {}]
    else
      base_attributes
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Les utilisateurs ne voient que les documents de leur organisation
      if user.admin? || user.super_admin?
        scope.all
      else
        # Documents dans des espaces
        space_docs = scope.joins(:space).where(spaces: { organization_id: user.organization_id })

        # Documents uploadés par l'utilisateur (sans espace)
        user_docs = scope.where(uploaded_by: user, space_id: nil)
        
        # Documents shared with the user
        shared_docs = scope.joins(:document_shares).where(document_shares: { shared_with: user, is_active: true })
                           .where('document_shares.expires_at IS NULL OR document_shares.expires_at > ?', Time.current)

        # Union of all three
        scope.where(id: space_docs.or(user_docs).or(shared_docs))
      end
    end
  end
end
