module Immo
  module Promo
    class DocumentPolicy < ApplicationPolicy
      class Scope < Scope
        def resolve
          case user.role
          when 'super_admin', 'admin'
            scope.all
          when 'project_manager'
            # Project managers can see all documents in their projects
            project_ids = user.managed_projects.pluck(:id)
            scope.where(
              documentable_type: ['Immo::Promo::Project', 'Immo::Promo::Phase', 'Immo::Promo::Task', 'Immo::Promo::Permit', 'Immo::Promo::Stakeholder']
            ).where(
              "documentable_type = 'Immo::Promo::Project' AND documentable_id IN (?) OR " \
              "documentable_type = 'Immo::Promo::Phase' AND documentable_id IN (SELECT id FROM immo_promo_phases WHERE project_id IN (?)) OR " \
              "documentable_type = 'Immo::Promo::Task' AND documentable_id IN (SELECT id FROM immo_promo_tasks WHERE phase_id IN (SELECT id FROM immo_promo_phases WHERE project_id IN (?))) OR " \
              "documentable_type = 'Immo::Promo::Permit' AND documentable_id IN (SELECT id FROM immo_promo_permits WHERE project_id IN (?)) OR " \
              "documentable_type = 'Immo::Promo::Stakeholder' AND documentable_id IN (SELECT id FROM immo_promo_stakeholders WHERE project_id IN (?))",
              project_ids, project_ids, project_ids, project_ids, project_ids
            )
          when 'stakeholder'
            # Stakeholders can see documents they have access to or are shared with them
            accessible_documents(scope)
          else
            # Regular users see documents they uploaded or have explicit access to
            accessible_documents(scope)
          end
        end

        private

        def accessible_documents(scope)
          # Documents uploaded by the user
          uploaded_docs = scope.where(uploaded_by: user)
          
          # Documents explicitly shared with the user
          shared_docs = scope.joins(:document_shares)
                            .where(document_shares: { shared_with_user: user })
                            .where('document_shares.expires_at IS NULL OR document_shares.expires_at > ?', Time.current)
          
          # Documents with authorization
          authorized_docs = scope.joins(:authorizations)
                                .where(authorizations: { 
                                  user: user, 
                                  permission_level: ['read', 'write', 'admin'],
                                  is_active: true 
                                })
                                .where('authorizations.expires_at IS NULL OR authorizations.expires_at > ?', Time.current)
          
          # Documents through group authorization
          group_authorized_docs = scope.joins(:authorizations)
                                      .joins('JOIN user_group_memberships ON authorizations.user_group_id = user_group_memberships.user_group_id')
                                      .where(
                                        user_group_memberships: { user: user },
                                        authorizations: { 
                                          permission_level: ['read', 'write', 'admin'],
                                          is_active: true 
                                        }
                                      )
                                      .where('authorizations.expires_at IS NULL OR authorizations.expires_at > ?', Time.current)

          # Combine all accessible documents
          scope.where(
            id: uploaded_docs.select(:id)
                .or(shared_docs.select(:id))
                .or(authorized_docs.select(:id))
                .or(group_authorized_docs.select(:id))
          )
        end
      end

      def index?
        # Can view document list if can access the parent resource
        case record.documentable
        when Immo::Promo::Project
          Immo::Promo::ProjectPolicy.new(user, record.documentable).show?
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          Immo::Promo::ProjectPolicy.new(user, record.documentable.project).show?
        else
          false
        end
      end

      def show?
        # Can view document if:
        # 1. Uploaded by user
        # 2. Has explicit read permission
        # 3. Has group read permission
        # 4. Document is shared with user
        # 5. Has access to parent resource
        return true if record.uploaded_by == user
        return true if user.super_admin?
        return true if record.readable_by?(user)
        
        # Check parent resource access
        case record.documentable
        when Immo::Promo::Project
          Immo::Promo::ProjectPolicy.new(user, record.documentable).show?
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          Immo::Promo::ProjectPolicy.new(user, record.documentable.project).show?
        else
          false
        end
      end

      def create?
        # Can create documents if can write to the parent resource
        case record.documentable
        when Immo::Promo::Project
          Immo::Promo::ProjectPolicy.new(user, record.documentable).update?
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          Immo::Promo::ProjectPolicy.new(user, record.documentable.project).update?
        else
          false
        end
      end

      def update?
        # Can update document if:
        # 1. Uploaded by user
        # 2. Has explicit write permission
        # 3. Has group write permission
        # 4. Has write access to parent resource
        return true if record.uploaded_by == user
        return true if user.super_admin?
        return true if record.writable_by?(user)
        
        # Check parent resource access
        case record.documentable
        when Immo::Promo::Project
          Immo::Promo::ProjectPolicy.new(user, record.documentable).update?
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          Immo::Promo::ProjectPolicy.new(user, record.documentable.project).update?
        else
          false
        end
      end

      def destroy?
        # Can delete document if:
        # 1. Uploaded by user
        # 2. Has admin permission
        # 3. Has admin access to parent resource
        return true if record.uploaded_by == user
        return true if user.super_admin?
        return true if record.admin_by?(user)
        
        # Check parent resource access
        case record.documentable
        when Immo::Promo::Project
          Immo::Promo::ProjectPolicy.new(user, record.documentable).update?
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          Immo::Promo::ProjectPolicy.new(user, record.documentable.project).update?
        else
          false
        end
      end

      def download?
        show?
      end

      def share?
        # Can share document if can read it and has write access to parent resource
        return false unless show?
        
        case record.documentable
        when Immo::Promo::Project
          Immo::Promo::ProjectPolicy.new(user, record.documentable).update?
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          Immo::Promo::ProjectPolicy.new(user, record.documentable.project).update?
        else
          false
        end
      end

      def request_validation?
        # Can request validation if:
        # 1. Has validation permission on document
        # 2. Has validation permission on parent resource
        return true if record.can_validate?(user)
        
        case record.documentable
        when Immo::Promo::Project
          record.documentable.can_validate?(user)
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          record.documentable.project.can_validate?(user)
        else
          false
        end
      end

      def bulk_upload?
        create?
      end

      def search?
        # Anyone can search, but results are filtered by scope
        true
      end

      # Document category specific permissions
      def access_technical_documents?
        return true if user.super_admin?
        return true if user.role.in?(['project_manager', 'architect', 'engineer'])
        
        # Check if user has technical role on the project
        case record.documentable
        when Immo::Promo::Project
          has_technical_role_on_project?(record.documentable)
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          has_technical_role_on_project?(record.documentable.project)
        else
          false
        end
      end

      def access_financial_documents?
        return true if user.super_admin?
        return true if user.role.in?(['project_manager', 'financial_manager'])
        
        # Check if user has financial role on the project
        case record.documentable
        when Immo::Promo::Project
          has_financial_role_on_project?(record.documentable)
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          has_financial_role_on_project?(record.documentable.project)
        else
          false
        end
      end

      def access_legal_documents?
        return true if user.super_admin?
        return true if user.role.in?(['project_manager', 'legal_advisor'])
        
        # Check if user has legal role on the project
        case record.documentable
        when Immo::Promo::Project
          has_legal_role_on_project?(record.documentable)
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          has_legal_role_on_project?(record.documentable.project)
        else
          false
        end
      end

      def access_permit_documents?
        return true if user.super_admin?
        return true if user.role.in?(['project_manager', 'architect', 'legal_advisor'])
        
        # Check if user has permit-related role on the project
        case record.documentable
        when Immo::Promo::Project
          has_permit_role_on_project?(record.documentable)
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          has_permit_role_on_project?(record.documentable.project)
        else
          false
        end
      end

      # Document workflow permissions
      def approve_document?
        return true if user.super_admin?
        return true if user.role.in?(['project_manager', 'validator'])
        
        # Check if user is a designated validator for the document type
        record.can_validate?(user)
      end

      def reject_document?
        approve_document?
      end

      def lock_document?
        return true if record.uploaded_by == user
        return true if user.super_admin?
        return true if record.admin_by?(user)
        
        update?
      end

      def unlock_document?
        return true if record.locked_by == user
        return true if record.uploaded_by == user
        return true if user.super_admin?
        return true if record.admin_by?(user)
        
        false
      end

      private

      def has_technical_role_on_project?(project)
        stakeholder = project.stakeholders.find_by(email: user.email)
        return false unless stakeholder
        
        stakeholder.stakeholder_type.in?(['architect', 'engineer', 'contractor', 'subcontractor'])
      end

      def has_financial_role_on_project?(project)
        stakeholder = project.stakeholders.find_by(email: user.email)
        return false unless stakeholder
        
        stakeholder.stakeholder_type.in?(['investor', 'financial_advisor']) ||
        project.project_manager == user
      end

      def has_legal_role_on_project?(project)
        stakeholder = project.stakeholders.find_by(email: user.email)
        return false unless stakeholder
        
        stakeholder.stakeholder_type.in?(['legal_advisor']) ||
        project.project_manager == user
      end

      def has_permit_role_on_project?(project)
        stakeholder = project.stakeholders.find_by(email: user.email)
        return false unless stakeholder
        
        stakeholder.stakeholder_type.in?(['architect', 'legal_advisor']) ||
        project.project_manager == user
      end
    end
  end
end