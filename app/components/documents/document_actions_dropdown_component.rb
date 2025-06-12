# frozen_string_literal: true

class Documents::DocumentActionsDropdownComponent < ViewComponent::Base
  include Turbo::FramesHelper

  attr_reader :document, :current_user

  def initialize(document:, current_user:)
    super
    @document = document
    @current_user = current_user
  end

  private

  def actions
    actions_list = []

    # Basic actions available to all users with read access
    if can?(:read, document)
      actions_list << { 
        label: "Télécharger", 
        icon: "download", 
        action: download_action,
        data: { turbo_method: :get }
      }
      
      actions_list << { 
        label: "Imprimer", 
        icon: "document", 
        action: "print",
        data: { action: "click->document-viewer#print" }
      }

      actions_list << {
        label: "Générer lien public",
        icon: "external_link",
        action: "generate-link",
        data: { action: "click->document-actions#generatePublicLink" }
      }
    end

    # Actions for users with write access
    if can?(:update, document)
      actions_list << { divider: true }
      
      actions_list << { 
        label: "Dupliquer", 
        icon: "clipboard", 
        action: duplicate_action,
        data: { turbo_method: :post, turbo_confirm: "Dupliquer ce document ?" }
      }
      
      actions_list << { 
        label: "Déplacer", 
        icon: "arrow_right", 
        action: "move",
        data: { action: "click->document-actions#move" }
      }
      
      actions_list << { 
        label: "Archiver", 
        icon: "download", 
        action: archive_action,
        data: { turbo_method: :patch, turbo_confirm: "Archiver ce document ?" }
      }
    end

    # Lock/unlock actions
    if can?(:lock, document)
      actions_list << { divider: true }
      
      if document.locked?
        actions_list << { 
          label: "Déverrouiller", 
          icon: "eye", 
          action: unlock_action,
          data: { turbo_method: :patch }
        }
      else
        actions_list << { 
          label: "Verrouiller", 
          icon: "eye_slash", 
          action: lock_action,
          data: { turbo_method: :patch }
        }
      end
    end

    # Validation actions
    if can?(:request_validation, document)
      actions_list << { divider: true }
      
      actions_list << {
        label: "Demander validation",
        icon: "check_circle",
        action: "request-validation",
        data: { action: "click->document-actions#requestValidation" }
      }
    end

    # Delete action (separate for emphasis)
    if can?(:destroy, document)
      actions_list << { divider: true }
      
      actions_list << { 
        label: "Supprimer", 
        icon: "trash", 
        action: delete_action,
        data: { turbo_method: :delete, turbo_confirm: "Êtes-vous sûr de vouloir supprimer ce document ?" },
        danger: true
      }
    end

    actions_list
  end

  def download_action
    helpers.download_ged_document_path(document)
  end

  def duplicate_action
    helpers.duplicate_ged_document_path(document)
  end

  def archive_action
    helpers.archive_ged_document_path(document)
  end

  def lock_action
    helpers.lock_ged_document_path(document)
  end

  def unlock_action
    helpers.unlock_ged_document_path(document)
  end

  def delete_action
    helpers.ged_document_path(document)
  end

  def can?(action, resource)
    return false unless current_user
    
    policy = Pundit.policy(current_user, resource)
    policy.public_send("#{action}?")
  rescue NoMethodError
    false
  end

  def folder_options
    return [] unless document.space
    
    folders = document.space.folders.where.not(id: document.folder_id)
    folders.map { |folder| [folder.name, folder.id] }
  end

  def validator_options
    return [] unless current_user.organization
    
    users = current_user.organization.users
                       .where.not(id: current_user.id)
                       .where(active: true)
                       .order(:last_name, :first_name)
    
    users.map { |user| [user.display_name, user.id] }
  end
end