# frozen_string_literal: true

class Ged::DocumentCardComponent < ApplicationComponent
  attr_reader :document, :current_user, :show_preview, :show_actions, :draggable, :layout

  def initialize(document:, current_user:, show_preview: true, show_actions: true, draggable: true, layout: :grid)
    @document = document
    @current_user = current_user
    @show_preview = show_preview
    @show_actions = show_actions
    @draggable = draggable
    @layout = layout # :grid or :list
  end

  private

  def thumbnail_with_fallback
    return icon_fallback unless document.file.attached?
    
    if show_preview && (document.has_thumbnail? || document.image?)
      image_thumbnail
    else
      icon_fallback
    end
  end

  def image_thumbnail
    content_tag(:div, class: "h-32 w-full bg-gray-50 relative overflow-hidden") do
      image_tag(
        thumbnail_url,
        class: "w-full h-full object-cover",
        alt: document.title,
        loading: "lazy",
        onerror: "this.onerror=null; this.parentElement.innerHTML='#{icon_fallback_html}'"
      )
    end
  end

  def icon_fallback
    content_tag(:div, class: "h-32 w-full bg-gradient-to-br from-gray-50 to-gray-100 flex items-center justify-center relative") do
      concat(file_type_icon)
      concat(file_extension_badge)
    end
  end

  def icon_fallback_html
    # Escaped HTML for onerror attribute
    "<div class='h-full w-full bg-gradient-to-br from-gray-50 to-gray-100 flex items-center justify-center'><span class='text-2xl font-bold text-gray-400'>#{document.file_extension&.upcase || 'FILE'}</span></div>"
  end

  def file_type_icon
    content_tag(:div, class: "text-gray-400") do
      helpers.heroicon(document_icon, variant: :solid, options: { class: "w-16 h-16" })
    end
  end

  def file_extension_badge
    return unless document.file_extension
    
    content_tag(:div, class: "absolute bottom-2 right-2") do
      content_tag(:span, 
        document.file_extension.upcase,
        class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-white bg-opacity-90 text-gray-700 shadow-sm"
      )
    end
  end

  def thumbnail_url
    return helpers.asset_path('document-placeholder.png') unless document.file.attached?
    
    if document.has_thumbnail?
      helpers.rails_blob_path(document.thumbnail)
    elsif document.image?
      helpers.rails_representation_path(document.file.variant(resize_to_limit: [400, 300]))
    else
      icon_path_for_document
    end
  rescue => e
    Rails.logger.error "Error generating thumbnail URL for document #{document.id}: #{e.message}"
    helpers.asset_path('document-placeholder.png')
  end

  def icon_path_for_document
    extension = document.file_extension&.delete('.')&.downcase
    icon_name = case extension
                when 'pdf' then 'pdf-icon.svg'
                when 'doc', 'docx' then 'word-icon.svg'
                when 'xls', 'xlsx' then 'excel-icon.svg'
                when 'ppt', 'pptx' then 'ppt-icon.svg'
                when 'zip', 'rar', '7z' then 'zip-icon.svg'
                when 'txt', 'md' then 'txt-icon.svg'
                else 'generic-icon.svg'
                end
    
    helpers.asset_path("file-icons/#{icon_name}")
  end

  def document_icon
    case document.document_type
    when 'pdf'
      'document-text'
    when 'word'
      'document'
    when 'excel'
      'table'
    when 'powerpoint'
      'presentation-chart-bar'
    when 'image'
      'photograph'
    when 'audio'
      'musical-note'
    when 'video'
      'video-camera'
    when 'mail'
      'envelope'
    when 'zip'
      'archive-box'
    else
      'document'
    end
  end

  def status_badge_classes
    base = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    case document.status
    when 'draft'
      "#{base} bg-gray-100 text-gray-800"
    when 'published'
      "#{base} bg-green-100 text-green-800"
    when 'locked'
      "#{base} bg-yellow-100 text-yellow-800"
    when 'archived'
      "#{base} bg-blue-100 text-blue-800"
    when 'marked_for_deletion'
      "#{base} bg-red-100 text-red-800"
    when 'deleted'
      "#{base} bg-red-100 text-red-800"
    else
      "#{base} bg-gray-100 text-gray-800"
    end
  end

  def status_text
    case document.status
    when 'draft'
      'Brouillon'
    when 'published'
      'Publié'
    when 'locked'
      'Verrouillé'
    when 'archived'
      'Archivé'
    when 'marked_for_deletion'
      'À supprimer'
    when 'deleted'
      'Supprimé'
    else
      document.status.humanize
    end
  end

  def document_actions
    actions = []

    # Basic actions available to all users with read access
    if can?(:read, document)
      actions << { 
        label: "Voir", 
        icon: "eye", 
        path: helpers.ged_document_path(document),
        method: :get,
        primary: true
      }
      
      if document.file.attached?
        actions << { 
          label: "Télécharger", 
          icon: "arrow-down-tray", 
          path: helpers.ged_download_document_path(document),
          method: :get,
          data: { turbo: false }
        }
      end
      
      # Preview action for supported formats
      if document.pdf? || document.image? || document.text?
        actions << {
          label: "Aperçu",
          icon: "magnifying-glass",
          action: "preview",
          data: { action: "click->document-actions#preview" }
        }
      end
    end

    return actions unless show_actions

    # Actions for users with write access
    if can?(:update, document)
      actions << { divider: true }
      
      actions << { 
        label: "Modifier", 
        icon: "pencil", 
        path: helpers.ged_edit_document_path(document),
        method: :get
      }
      
      actions << { 
        label: "Dupliquer", 
        icon: "square-2-stack", 
        path: helpers.ged_duplicate_document_path(document),
        method: :post,
        data: { turbo_method: :post, turbo_confirm: "Dupliquer ce document ?" }
      }
      
      actions << { 
        label: "Déplacer", 
        icon: "arrow-right", 
        action: "move",
        data: { action: "click->document-actions#move" }
      }
    end

    # Lock/unlock actions
    if can?(:lock, document)
      actions << { divider: true } unless actions.last&.dig(:divider)
      
      if document.locked?
        actions << { 
          label: "Déverrouiller", 
          icon: "lock-open", 
          path: helpers.ged_unlock_document_path(document),
          method: :patch,
          data: { turbo_method: :patch }
        }
      else
        actions << { 
          label: "Verrouiller", 
          icon: "lock-closed", 
          path: helpers.ged_lock_document_path(document),
          method: :patch,
          data: { turbo_method: :patch }
        }
      end
    end

    # Validation actions
    if can?(:request_validation, document)
      actions << { divider: true } unless actions.last&.dig(:divider)
      
      actions << {
        label: "Demander validation",
        icon: "check-circle",
        action: "request-validation",
        data: { action: "click->document-actions#requestValidation" }
      }
    end

    # Archive action
    if can?(:update, document) && !document.archived?
      actions << { divider: true } unless actions.last&.dig(:divider)
      
      actions << { 
        label: "Archiver", 
        icon: "archive-box", 
        path: helpers.ged_archive_document_path(document),
        method: :patch,
        data: { turbo_method: :patch, turbo_confirm: "Archiver ce document ?" }
      }
    end

    # Delete action (separate for emphasis)
    if can?(:destroy, document)
      actions << { divider: true }
      
      actions << { 
        label: "Supprimer", 
        icon: "trash", 
        path: helpers.ged_document_path(document),
        method: :delete,
        data: { turbo_method: :delete, turbo_confirm: "Êtes-vous sûr de vouloir supprimer ce document ?" },
        danger: true
      }
    end

    actions
  end

  def quick_actions
    # Returns only the most important actions for quick access
    actions = []
    
    if document.file.attached? && can?(:read, document)
      actions << {
        icon: "arrow-down-tray",
        path: helpers.ged_download_document_path(document),
        title: "Télécharger",
        class: "text-gray-400 hover:text-gray-600",
        data: { turbo: false }
      }
    end
    
    if (document.pdf? || document.image?) && can?(:read, document)
      actions << {
        icon: "magnifying-glass",
        action: "preview",
        title: "Aperçu",
        class: "text-gray-400 hover:text-gray-600",
        data: { action: "click->document-actions#preview" }
      }
    end
    
    if can?(:share, document)
      actions << {
        icon: "share",
        action: "share",
        title: "Partager",
        class: "text-gray-400 hover:text-gray-600",
        data: { action: "click->document-actions#share" }
      }
    end
    
    actions
  end

  def formatted_date
    return nil unless document.updated_at
    
    if document.updated_at > 1.week.ago
      time_ago_in_words(document.updated_at) + " ago"
    else
      l(document.updated_at, format: :short)
    end
  end

  def file_size
    return nil unless document.file.attached?
    
    size = document.file.blob.byte_size
    if size < 1024
      "#{size} B"
    elsif size < 1048576
      "#{(size / 1024.0).round(1)} KB"
    else
      "#{(size / 1048576.0).round(1)} MB"
    end
  end

  def document_link_path
    helpers.ged_document_path(document)
  end

  def document_link_options
    options = {
      class: "block hover:text-primary-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 rounded"
    }
    
    if document.pdf? || document.image?
      options[:data] = {
        action: "click->document-actions#openPreview",
        document_id: document.id,
        turbo: false
      }
    end
    
    options
  end

  def can?(action, resource)
    return false unless current_user
    
    policy = Pundit.policy(current_user, resource)
    policy.public_send("#{action}?")
  rescue NoMethodError
    false
  end

  def card_classes
    base_classes = if layout == :list
      "bg-white shadow-sm border border-gray-200 rounded-lg hover:shadow-md transition-all duration-200 group"
    else
      "bg-white overflow-hidden shadow rounded-lg hover:shadow-lg transition-all duration-200 group"
    end
    
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
      document_id: document.id,
      document_title: document.title,
      controller: "drag-drop document-actions",
      action: "dragstart->drag-drop#handleDragStart dragend->drag-drop#handleDragEnd"
    }
  end

  def status_indicators
    indicators = []
    
    # Lock indicator
    if document.locked?
      indicators << {
        icon: "lock-closed",
        color: "text-yellow-500",
        title: "Document verrouillé"
      }
    end
    
    # Processing indicator based on processing_status
    if document.respond_to?(:processing_status) && document.processing_status == 'processing'
      indicators << {
        icon: "arrow-path",
        color: "text-purple-500 animate-spin",
        title: "Document en traitement"
      }
    end
    
    # Validation indicator
    if document.validation_pending?
      indicators << {
        icon: "clock",
        color: "text-orange-500",
        title: "Validation en attente"
      }
    elsif document.validated?
      indicators << {
        icon: "check-circle",
        color: "text-green-500",
        title: "Document validé"
      }
    elsif document.validation_rejected?
      indicators << {
        icon: "x-circle",
        color: "text-red-500",
        title: "Document rejeté"
      }
    end
    
    indicators
  end
end