# frozen_string_literal: true

class Ged::FolderCardComponent < ApplicationComponent
  attr_reader :folder, :current_user, :show_actions, :draggable

  def initialize(folder:, current_user:, show_actions: true, draggable: true)
    @folder = folder
    @current_user = current_user
    @show_actions = show_actions
    @draggable = draggable
  end

  private

  def document_count_text
    count = folder.documents.count
    if count == 0
      "Aucun document"
    else
      pluralize(count, 'document')
    end
  end

  def children_count_text
    count = folder.children.count
    return nil if count == 0
    
    pluralize(count, 'sous-dossier')
  end

  def folder_metadata
    metadata_parts = [document_count_text]
    metadata_parts << children_count_text if children_count_text
    metadata_parts.join(' • ')
  end

  def folder_actions
    actions = []

    # Basic view action
    actions << {
      label: "Ouvrir",
      icon: "folder-open",
      path: helpers.ged_folder_path(folder),
      method: :get,
      primary: true
    }

    return actions unless show_actions

    # Permission-based actions
    if can?(:update, folder)
      actions << { divider: true }
      
      actions << {
        label: "Renommer",
        icon: "pencil",
        action: "rename",
        data: { action: "click->folder-actions#rename" }
      }
      
      actions << {
        label: "Déplacer",
        icon: "arrow-right",
        action: "move",
        data: { action: "click->folder-actions#move" }
      }
    end

    if can?(:admin, folder)
      actions << { divider: true } unless actions.last&.dig(:divider)
      
      actions << {
        label: "Gérer les droits",
        icon: "lock-closed",
        path: helpers.ged_folder_permissions_path(folder),
        method: :get
      }
    end

    # Delete action (separate for emphasis)
    if can?(:destroy, folder)
      actions << { divider: true }
      
      actions << {
        label: "Supprimer",
        icon: "trash",
        path: helpers.ged_folder_path(folder),
        method: :delete,
        data: { 
          turbo_method: :delete, 
          turbo_confirm: "Êtes-vous sûr de vouloir supprimer ce dossier ? Cette action supprimera également tous les documents qu'il contient." 
        },
        danger: true
      }
    end

    actions
  end

  def quick_actions
    # Returns only the most important actions for quick access
    actions = []
    
    if can?(:admin, folder)
      actions << {
        icon: "lock-closed",
        path: helpers.ged_folder_permissions_path(folder),
        title: "Gérer les droits",
        class: "text-gray-400 hover:text-gray-600"
      }
    end
    
    if can?(:update, folder)
      actions << {
        icon: "pencil",
        action: "rename",
        title: "Renommer",
        class: "text-gray-400 hover:text-gray-600",
        data: { action: "click->folder-actions#rename" }
      }
    end
    
    actions
  end

  def folder_link_path
    helpers.ged_folder_path(folder)
  end

  def folder_link_options
    {
      class: "absolute inset-0 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 rounded-lg",
      title: "Ouvrir #{folder.name}"
    }
  end

  def can?(action, resource)
    return false unless current_user
    
    policy = Pundit.policy(current_user, resource)
    policy.public_send("#{action}?")
  rescue NoMethodError
    false
  end

  def folder_icon_classes
    "h-8 w-8 text-blue-500 group-hover:text-blue-600 transition-colors"
  end

  def card_classes
    base_classes = "relative rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm hover:border-gray-400 hover:shadow-md cursor-pointer group transition-all duration-200"
    
    if draggable
      "#{base_classes} draggable"
    else
      base_classes
    end
  end

  def drag_data_attributes
    return {} unless draggable
    
    {
      draggable: true,
      folder_id: folder.id,
      folder_name: folder.name,
      controller: "drag-drop",
      action: "dragstart->drag-drop#handleDragStart dragend->drag-drop#handleDragEnd"
    }
  end

  def formatted_updated_at
    return nil unless folder.updated_at
    
    if folder.updated_at > 1.week.ago
      time_ago_in_words(folder.updated_at) + " ago"
    else
      l(folder.updated_at, format: :short)
    end
  end
end