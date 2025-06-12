class Documents::DocumentCardComponent < ApplicationComponent
  def initialize(document:, show_preview: true, show_actions: true, clickable: true)
    @document = document
    @show_preview = show_preview
    @show_actions = show_actions
    @clickable = clickable
  end

  private

  attr_reader :document, :show_preview, :show_actions, :clickable

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
        alt: document.name,
        loading: "lazy",
        onerror: "this.onerror=null; this.parentElement.innerHTML='#{icon_fallback_html}'"
      )
    end
  end

  def icon_fallback
    content_tag(:div, class: "h-32 w-full bg-gradient-to-br from-gray-50 to-gray-100 flex items-center justify-center") do
      concat(file_type_icon)
      concat(file_extension_badge)
    end
  end

  def icon_fallback_html
    # Escaped HTML for onerror attribute
    "<div class='h-full w-full bg-gradient-to-br from-gray-50 to-gray-100 flex items-center justify-center'><span class='text-2xl font-bold text-gray-400'>#{document.file_extension&.upcase || 'FILE'}</span></div>"
  end

  def file_type_icon
    if document.respond_to?(:icon_for_content_type) && document.icon_for_content_type
      image_tag(
        document.icon_for_content_type,
        class: "w-16 h-16 opacity-50",
        alt: "File type icon"
      )
    else
      content_tag(:div, class: "text-gray-400") do
        helpers.heroicon(document_icon, variant: :solid, options: { class: "w-16 h-16" })
      end
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
      'volume-up'
    when 'video'
      'video-camera'
    when 'mail'
      'mail'
    when 'zip'
      'archive'
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
    else
      "#{base} bg-gray-100 text-gray-800"
    end
  end

  def formatted_date
    l(document.created_at, format: :short) if document.created_at
  end

  def file_size
    return unless document.file.attached?
    
    size = document.file.blob.byte_size
    if size < 1024
      "#{size} B"
    elsif size < 1048576
      "#{(size / 1024.0).round(1)} KB"
    else
      "#{(size / 1048576.0).round(1)} MB"
    end
  end

  def actions_for_document
    actions = []
    
    # Basic actions available to all
    actions << { 
      label: "View", 
      path: helpers.ged_document_path(document),
      icon: "eye",
      method: :get
    }
    
    if document.file.attached?
      actions << { 
        label: "Download", 
        path: helpers.ged_download_document_path(document),
        icon: "download",
        method: :get,
        data: { turbo: false }
      }
    end
    
    # Preview action for supported formats
    if document.pdf? || document.image? || document.text?
      actions << {
        label: "Preview",
        path: "#",
        icon: "eye",
        method: :get,
        data: { 
          action: "click->document-preview#open",
          document_id: document.id
        }
      }
    end
    
    # Actions based on permissions
    if helpers.policy(document).update?
      actions << { 
        label: "Edit", 
        path: helpers.ged_edit_document_path(document),
        icon: "pencil",
        method: :get
      }
    end
    
    if helpers.policy(document).share?
      actions << { 
        label: "Share", 
        path: helpers.new_ged_document_document_share_path(document),
        icon: "share",
        method: :get
      }
    end
    
    if helpers.policy(document).destroy?
      actions << {
        label: "Delete",
        path: helpers.ged_document_path(document),
        icon: "trash",
        method: :delete,
        data: { 
          confirm: "Are you sure you want to delete this document?",
          turbo_method: :delete 
        },
        class: "text-red-600 hover:text-red-700"
      }
    end
    
    actions
  end

  def quick_actions
    # Returns only the most important actions for quick access
    actions = []
    
    if document.file.attached?
      actions << {
        icon: "download",
        path: helpers.ged_download_document_path(document),
        title: "Download",
        class: "text-gray-400 hover:text-gray-600"
      }
    end
    
    if document.pdf? || document.image?
      actions << {
        icon: "eye",
        path: "#",
        title: "Preview",
        class: "text-gray-400 hover:text-gray-600",
        data: {
          action: "click->document-preview#open",
          document_id: document.id
        }
      }
    end
    
    if helpers.policy(document).share?
      actions << {
        icon: "share",
        path: helpers.new_ged_document_document_share_path(document),
        title: "Share",
        class: "text-gray-400 hover:text-gray-600"
      }
    end
    
    actions
  end

  def main_link_path
    clickable ? helpers.ged_document_path(document) : "#"
  end

  def main_link_options
    options = {
      class: "block hover:text-primary-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 rounded"
    }
    
    if clickable && (document.pdf? || document.image?)
      options[:data] = {
        action: "click->document-preview#open",
        document_id: document.id,
        turbo: false
      }
    end
    
    options
  end
end