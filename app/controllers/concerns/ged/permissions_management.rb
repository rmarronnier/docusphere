module Ged
  module PermissionsManagement
    extend ActiveSupport::Concern

    def space_permissions
      @space = policy_scope(Space).find(params[:id])
      authorize @space, :manage_permissions?
      @authorizations = @space.authorizations.includes(:user, :user_group)
      @users = User.where(organization: current_user.organization)
      @user_groups = UserGroup.where(organization: current_user.organization)
    end

    def update_space_permissions
      @space = policy_scope(Space).find(params[:id])
      authorize @space, :manage_permissions?
      
      if update_authorizations(@space, permission_params[:authorizations])
        render json: { success: true, message: 'Permissions mises à jour avec succès' }
      else
        render json: { success: false, errors: ['Erreur lors de la mise à jour des permissions'] }
      end
    end

    def folder_permissions
      @folder = policy_scope(Folder).find(params[:id])
      authorize @folder, :manage_permissions?
      @authorizations = @folder.authorizations.includes(:user, :user_group)
      @users = User.where(organization: current_user.organization)
      @user_groups = UserGroup.where(organization: current_user.organization)
    end

    def update_folder_permissions
      @folder = policy_scope(Folder).find(params[:id])
      authorize @folder, :manage_permissions?
      
      if update_authorizations(@folder, permission_params[:authorizations])
        render json: { success: true, message: 'Permissions mises à jour avec succès' }
      else
        render json: { success: false, errors: ['Erreur lors de la mise à jour des permissions'] }
      end
    end

    def document_permissions
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :manage_permissions?
      @authorizations = @document.authorizations.includes(:user, :user_group)
      @users = User.where(organization: current_user.organization)
      @user_groups = UserGroup.where(organization: current_user.organization)
    end

    def update_document_permissions
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :manage_permissions?
      
      if update_authorizations(@document, permission_params[:authorizations])
        render json: { success: true, message: 'Permissions mises à jour avec succès' }
      else
        render json: { success: false, errors: ['Erreur lors de la mise à jour des permissions'] }
      end
    end

    private

    def permission_params
      params.require(:permissions).permit(authorizations: [:user_id, :user_group_id, :permission_level, :_destroy])
    end

    def update_authorizations(resource, authorizations_data)
      return true unless authorizations_data.present?
      
      ActiveRecord::Base.transaction do
        authorizations_data.each do |auth_data|
          if auth_data[:_destroy]
            resource.authorizations.find_by(
              user_id: auth_data[:user_id],
              user_group_id: auth_data[:user_group_id]
            )&.destroy
          else
            auth = resource.authorizations.find_or_initialize_by(
              user_id: auth_data[:user_id],
              user_group_id: auth_data[:user_group_id]
            )
            auth.update!(
              permission_level: auth_data[:permission_level],
              granted_by: current_user,
              granted_at: Time.current
            )
          end
        end
        true
      end
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end